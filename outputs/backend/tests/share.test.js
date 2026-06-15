import request from 'supertest';
import app from '../src/app.js';
import db from '../src/config/db.js';
import { initDatabase } from '../src/config/initDb.js';
import bcrypt from 'bcrypt';
import jwt from 'jsonwebtoken';
import config from '../src/config/environment.js';

describe('Journal Sharing APIs (Module 8)', () => {
  let user1Token;
  let user2Token;
  let user1Id = 'u-share-user1';
  let user2Id = 'u-share-user2';
  let journal1Id = 'j-share-journal1';
  let journal2Id = 'j-share-journal2';

  beforeAll(async () => {
    // Re-initialize database schema
    await initDatabase(false);
    await db.run('DELETE FROM User;');

    // Hash password
    const passwordHash = await bcrypt.hash('Password123!', 10);

    // Insert test users
    await db.run(
      'INSERT INTO User (user_id, full_name, email, password_hash, account_status) VALUES (?, ?, ?, ?, ?);',
      [user1Id, 'User One', 'user1@example.com', passwordHash, 'Verified']
    );

    await db.run(
      'INSERT INTO User (user_id, full_name, email, password_hash, account_status) VALUES (?, ?, ?, ?, ?);',
      [user2Id, 'User Two', 'user2@example.com', passwordHash, 'Verified']
    );

    // Generate JWT access tokens
    user1Token = jwt.sign(
      { userId: user1Id, email: 'user1@example.com', fullName: 'User One' },
      config.jwt.secret,
      { expiresIn: '15m' }
    );

    user2Token = jwt.sign(
      { userId: user2Id, email: 'user2@example.com', fullName: 'User Two' },
      config.jwt.secret,
      { expiresIn: '15m' }
    );

    // Insert sessions to pass authMiddleware checks
    const expiresAt = new Date(Date.now() + 15 * 60 * 1000).toISOString();
    await db.run(
      'INSERT INTO UserSession (session_id, user_id, access_token, refresh_token, expires_at, is_active) VALUES (?, ?, ?, ?, ?, ?);',
      ['sess-share-1', user1Id, user1Token, 'refresh-share-1', expiresAt, 1]
    );
    await db.run(
      'INSERT INTO UserSession (session_id, user_id, access_token, refresh_token, expires_at, is_active) VALUES (?, ?, ?, ?, ?, ?);',
      ['sess-share-2', user2Id, user2Token, 'refresh-share-2', expiresAt, 1]
    );

    // Insert test journals
    await db.run(
      'INSERT INTO JournalEntry (journal_id, user_id, title, content, entry_date, word_count, is_private) VALUES (?, ?, ?, ?, ?, ?, ?);',
      [journal1Id, user1Id, 'User 1 Entry', 'This is content for user 1 journal.', '2026-06-11', 8, 1]
    );

    await db.run(
      'INSERT INTO JournalEntry (journal_id, user_id, title, content, entry_date, word_count, is_private) VALUES (?, ?, ?, ?, ?, ?, ?);',
      [journal2Id, user2Id, 'User 2 Entry', 'This is content for user 2 journal.', '2026-06-11', 8, 1]
    );
  });

  afterAll(async () => {
    await db.close();
  });

  describe('POST /api/v1/journals/:journalId/share', () => {
    it('should successfully generate a share link for owned journal', async () => {
      const res = await request(app)
        .post(`/api/v1/journals/${journal1Id}/share`)
        .set('Authorization', `Bearer ${user1Token}`);

      expect(res.statusCode).toBe(201);
      expect(res.body).toHaveProperty('shareUrl');
      expect(res.body).toHaveProperty('shareToken');
      expect(res.body.shareUrl).toContain(res.body.shareToken);

      // Verify db insertion
      const activeShare = await db.get(
        'SELECT * FROM JournalShare WHERE journal_id = ? AND is_active = 1;',
        [journal1Id]
      );
      expect(activeShare).toBeDefined();
      expect(activeShare.share_token).toBe(res.body.shareToken);

      // Verify AuditLog creation
      const audit = await db.get(
        "SELECT * FROM AuditLog WHERE entity_id = ? AND action_type = 'Share';",
        [journal1Id]
      );
      expect(audit).toBeDefined();
      expect(audit.user_id).toBe(user1Id);
      expect(audit.metadata).toContain(res.body.shareToken);
    });

    it('should reject sharing if the journal belongs to another user with 403 ACCESS_DENIED', async () => {
      const res = await request(app)
        .post(`/api/v1/journals/${journal2Id}/share`)
        .set('Authorization', `Bearer ${user1Token}`);

      expect(res.statusCode).toBe(403);
      expect(res.body.errorCode).toBe('ACCESS_DENIED');
    });

    it('should reject sharing for a nonexistent journal with 404 ENTRY_NOT_FOUND', async () => {
      const res = await request(app)
        .post('/api/v1/journals/j-nonexistent/share')
        .set('Authorization', `Bearer ${user1Token}`);

      expect(res.statusCode).toBe(404);
      expect(res.body.errorCode).toBe('ENTRY_NOT_FOUND');
    });

    it('should reject sharing if unauthenticated with 401', async () => {
      const res = await request(app).post(`/api/v1/journals/${journal1Id}/share`);
      expect(res.statusCode).toBe(401);
    });
  });

  describe('GET /api/v1/share/:shareToken', () => {
    let activeToken;

    beforeAll(async () => {
      const share = await db.get(
        'SELECT share_token FROM JournalShare WHERE journal_id = ? AND is_active = 1;',
        [journal1Id]
      );
      activeToken = share.share_token;
    });

    it('should allow public unauthenticated access to view-only journal content', async () => {
      const res = await request(app).get(`/api/v1/share/${activeToken}`);

      expect(res.statusCode).toBe(200);
      expect(res.body).toHaveProperty('journalId', journal1Id);
      expect(res.body).toHaveProperty('title', 'User 1 Entry');
      expect(res.body).toHaveProperty('content', 'This is content for user 1 journal.');
      expect(res.body).not.toHaveProperty('userId');
      expect(res.body).not.toHaveProperty('isPrivate');
    });

    it('should return 404 with INVALID_SHARE_TOKEN for a nonexistent token', async () => {
      const res = await request(app).get('/api/v1/share/nonexistent-token');

      expect(res.statusCode).toBe(404);
      expect(res.body.errorCode).toBe('INVALID_SHARE_TOKEN');
    });
  });

  describe('DELETE /api/v1/journals/:journalId/share', () => {
    it('should reject revocation if the journal belongs to another user with 403 ACCESS_DENIED', async () => {
      const res = await request(app)
        .delete(`/api/v1/journals/${journal2Id}/share`)
        .set('Authorization', `Bearer ${user1Token}`);

      expect(res.statusCode).toBe(403);
      expect(res.body.errorCode).toBe('ACCESS_DENIED');
    });

    it('should successfully revoke share link for owned journal', async () => {
      const res = await request(app)
        .delete(`/api/v1/journals/${journal1Id}/share`)
        .set('Authorization', `Bearer ${user1Token}`);

      expect(res.statusCode).toBe(200);
      expect(res.body).toHaveProperty('message');

      // Verify db deactivation
      const activeShare = await db.get(
        'SELECT * FROM JournalShare WHERE journal_id = ? AND is_active = 1;',
        [journal1Id]
      );
      expect(activeShare).toBeUndefined();

      // Verify AuditLog creation
      const audit = await db.get(
        "SELECT * FROM AuditLog WHERE entity_id = ? AND action_type = 'RevokeShare';",
        [journal1Id]
      );
      expect(audit).toBeDefined();
      expect(audit.user_id).toBe(user1Id);
    });

    it('should return 404 SHARE_NOT_FOUND when revoking an already revoked or nonexistent share', async () => {
      const res = await request(app)
        .delete(`/api/v1/journals/${journal1Id}/share`)
        .set('Authorization', `Bearer ${user1Token}`);

      expect(res.statusCode).toBe(404);
      expect(res.body.errorCode).toBe('SHARE_NOT_FOUND');
    });

    it('should return 404 with SHARE_REVOKED on public access after revocation', async () => {
      const share = await db.get(
        'SELECT share_token FROM JournalShare WHERE journal_id = ? ORDER BY created_at DESC LIMIT 1;',
        [journal1Id]
      );
      const revokedToken = share.share_token;

      const res = await request(app).get(`/api/v1/share/${revokedToken}`);

      expect(res.statusCode).toBe(404);
      expect(res.body.errorCode).toBe('SHARE_REVOKED');
    });
  });
});
