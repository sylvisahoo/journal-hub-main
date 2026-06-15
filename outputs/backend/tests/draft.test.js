import request from 'supertest';
import app from '../src/app.js';
import db from '../src/config/db.js';
import { initDatabase } from '../src/config/initDb.js';
import bcrypt from 'bcrypt';
import jwt from 'jsonwebtoken';
import config from '../src/config/environment.js';

describe('Draft Management APIs', () => {
  let user1Token;
  let user2Token;
  let user1Id = 'u-user1-test';
  let user2Id = 'u-user2-test';

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

    // Insert active sessions into UserSession table to pass authMiddleware checks
    const expiresAt = new Date(Date.now() + 15 * 60 * 1000).toISOString();
    await db.run(
      'INSERT INTO UserSession (session_id, user_id, access_token, refresh_token, expires_at, is_active) VALUES (?, ?, ?, ?, ?, ?);',
      ['s-user1-test', user1Id, user1Token, 'refresh-token-1', expiresAt, 1]
    );
    await db.run(
      'INSERT INTO UserSession (session_id, user_id, access_token, refresh_token, expires_at, is_active) VALUES (?, ?, ?, ?, ?, ?);',
      ['s-user2-test', user2Id, user2Token, 'refresh-token-2', expiresAt, 1]
    );
  });

  afterAll(async () => {
    await db.close();
  });

  describe('POST /api/v1/drafts', () => {
    let createdDraftId;

    it('should successfully create a new draft', async () => {
      const res = await request(app)
        .post('/api/v1/drafts')
        .set('Authorization', `Bearer ${user1Token}`)
        .send({
          title: 'My First Draft',
          content: 'This is the draft content.',
          deviceIdentifier: 'mobile'
        });

      expect(res.statusCode).toBe(200);
      expect(res.body).toHaveProperty('draftId');
      expect(res.body).toHaveProperty('syncStatus', 'Synced');
      createdDraftId = res.body.draftId;

      // Verify db insertion
      const dbDraft = await db.get('SELECT * FROM Draft WHERE draft_id = ?;', [createdDraftId]);
      expect(dbDraft).toBeDefined();
      expect(dbDraft.user_id).toBe(user1Id);
      expect(dbDraft.title).toBe('My First Draft');
      expect(dbDraft.content).toBe('This is the draft content.');
    });

    it('should successfully update existing draft', async () => {
      const res = await request(app)
        .post('/api/v1/drafts')
        .set('Authorization', `Bearer ${user1Token}`)
        .send({
          draftId: createdDraftId,
          title: 'Updated Draft Title',
          content: 'Updated draft content.'
        });

      expect(res.statusCode).toBe(200);
      expect(res.body.draftId).toBe(createdDraftId);

      const dbDraft = await db.get('SELECT * FROM Draft WHERE draft_id = ?;', [createdDraftId]);
      expect(dbDraft.title).toBe('Updated Draft Title');
      expect(dbDraft.content).toBe('Updated draft content.');
    });

    it('should reject update if the draft is owned by another user with 403 ACCESS_DENIED', async () => {
      const res = await request(app)
        .post('/api/v1/drafts')
        .set('Authorization', `Bearer ${user2Token}`)
        .send({
          draftId: createdDraftId,
          title: 'Hacked Title',
          content: 'Hacked content.'
        });

      expect(res.statusCode).toBe(403);
      expect(res.body.errorCode).toBe('ACCESS_DENIED');
    });

    it('should reject requests without authorization token with 401 UNAUTHORIZED', async () => {
      const res = await request(app)
        .post('/api/v1/drafts')
        .send({
          title: 'Unauthenticated Draft'
        });

      expect(res.statusCode).toBe(401);
    });
  });

  describe('GET /api/v1/drafts/:draftId', () => {
    let draftId = 'd-fixed-test-id';

    beforeEach(async () => {
      await db.run('DELETE FROM Draft WHERE draft_id = ?;', [draftId]);
      await db.run(
        'INSERT INTO Draft (draft_id, user_id, title, content, sync_status) VALUES (?, ?, ?, ?, ?);',
        [draftId, user1Id, 'Get Draft Test', 'Get content test', 'Synced']
      );
    });

    it('should successfully retrieve owned draft details', async () => {
      const res = await request(app)
        .get(`/api/v1/drafts/${draftId}`)
        .set('Authorization', `Bearer ${user1Token}`);

      expect(res.statusCode).toBe(200);
      expect(res.body.draftId).toBe(draftId);
      expect(res.body.title).toBe('Get Draft Test');
      expect(res.body.content).toBe('Get content test');
      expect(res.body.userId).toBe(user1Id);
    });

    it('should reject retrieval if owned by another user with 403 ACCESS_DENIED', async () => {
      const res = await request(app)
        .get(`/api/v1/drafts/${draftId}`)
        .set('Authorization', `Bearer ${user2Token}`);

      expect(res.statusCode).toBe(403);
      expect(res.body.errorCode).toBe('ACCESS_DENIED');
    });

    it('should return 404 DRAFT_NOT_FOUND if draftId does not exist', async () => {
      const res = await request(app)
        .get('/api/v1/drafts/d-nonexistent')
        .set('Authorization', `Bearer ${user1Token}`);

      expect(res.statusCode).toBe(404);
      expect(res.body.errorCode).toBe('DRAFT_NOT_FOUND');
    });
  });
});
