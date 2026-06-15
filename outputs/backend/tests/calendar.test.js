import request from 'supertest';
import app from '../src/app.js';
import db from '../src/config/db.js';
import { initDatabase } from '../src/config/initDb.js';
import bcrypt from 'bcrypt';
import jwt from 'jsonwebtoken';
import config from '../src/config/environment.js';

describe('Calendar Navigation APIs', () => {
  let user1Token;
  let user2Token;
  let user1Id = 'u-cal-user1';
  let user2Id = 'u-cal-user2';

  beforeAll(async () => {
    // Re-initialize database schema
    await initDatabase(false);
    await db.run('DELETE FROM User;');

    // Hash password
    const passwordHash = await bcrypt.hash('Password123!', 10);

    // Insert test users
    await db.run(
      'INSERT INTO User (user_id, full_name, email, password_hash, account_status) VALUES (?, ?, ?, ?, ?);',
      [user1Id, 'Calendar User One', 'cal1@example.com', passwordHash, 'Verified']
    );

    await db.run(
      'INSERT INTO User (user_id, full_name, email, password_hash, account_status) VALUES (?, ?, ?, ?, ?);',
      [user2Id, 'Calendar User Two', 'cal2@example.com', passwordHash, 'Verified']
    );

    // Generate JWT access tokens
    user1Token = jwt.sign(
      { userId: user1Id, email: 'cal1@example.com', fullName: 'Calendar User One' },
      config.jwt.secret,
      { expiresIn: '15m' }
    );

    user2Token = jwt.sign(
      { userId: user2Id, email: 'cal2@example.com', fullName: 'Calendar User Two' },
      config.jwt.secret,
      { expiresIn: '15m' }
    );

    // Insert active sessions into UserSession table
    const expiresAt = new Date(Date.now() + 15 * 60 * 1000).toISOString();
    await db.run(
      'INSERT INTO UserSession (session_id, user_id, access_token, refresh_token, expires_at, is_active) VALUES (?, ?, ?, ?, ?, ?);',
      ['s-cal1', user1Id, user1Token, 'refresh-token-c1', expiresAt, 1]
    );
    await db.run(
      'INSERT INTO UserSession (session_id, user_id, access_token, refresh_token, expires_at, is_active) VALUES (?, ?, ?, ?, ?, ?);',
      ['s-cal2', user2Id, user2Token, 'refresh-token-c2', expiresAt, 1]
    );

    // Seed test journal entries
    // User 1 entries
    await db.run(
      'INSERT INTO JournalEntry (journal_id, user_id, title, content, entry_date, word_count, is_private, version_number) VALUES (?, ?, ?, ?, ?, ?, ?, ?);',
      ['j-c1', user1Id, 'Entry 1', 'Content 1', '2026-06-11T12:00:00.000Z', 2, 1, 1]
    );
    await db.run(
      'INSERT INTO JournalEntry (journal_id, user_id, title, content, entry_date, word_count, is_private, version_number) VALUES (?, ?, ?, ?, ?, ?, ?, ?);',
      ['j-c2', user1Id, 'Entry 2', 'Content 2', '2026-06-15', 2, 1, 1]
    );
    // User 1 entry in another month
    await db.run(
      'INSERT INTO JournalEntry (journal_id, user_id, title, content, entry_date, word_count, is_private, version_number) VALUES (?, ?, ?, ?, ?, ?, ?, ?);',
      ['j-c3', user1Id, 'Entry 3', 'Content 3', '2026-07-01', 2, 1, 1]
    );
    // User 1 deleted entry (should not be highlighted)
    await db.run(
      'INSERT INTO JournalEntry (journal_id, user_id, title, content, entry_date, word_count, is_private, version_number, deleted_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP);',
      ['j-c4', user1Id, 'Deleted Entry', 'Content', '2026-06-20', 2, 1, 1]
    );

    // User 2 entries (should not leak to User 1)
    await db.run(
      'INSERT INTO JournalEntry (journal_id, user_id, title, content, entry_date, word_count, is_private, version_number) VALUES (?, ?, ?, ?, ?, ?, ?, ?);',
      ['j-c5', user2Id, 'Entry 5', 'Content 5', '2026-06-18', 2, 1, 1]
    );
  });

  afterAll(async () => {
    await db.close();
  });

  describe('GET /api/v1/calendar', () => {
    it('should successfully get highlighted dates for the current user and month', async () => {
      const res = await request(app)
        .get('/api/v1/calendar')
        .query({ month: 6, year: 2026 })
        .set('Authorization', `Bearer ${user1Token}`);

      expect(res.statusCode).toBe(200);
      expect(Array.isArray(res.body)).toBe(true);
      expect(res.body).toHaveLength(2);
      expect(res.body).toContain('2026-06-11');
      expect(res.body).toContain('2026-06-15');
      // Should not contain deleted entry date
      expect(res.body).not.toContain('2026-06-20');
      // Should not contain User 2's entry date
      expect(res.body).not.toContain('2026-06-18');
      // Should not contain another month's entry date
      expect(res.body).not.toContain('2026-07-01');
    });

    it('should retrieve correct dates for another month', async () => {
      const res = await request(app)
        .get('/api/v1/calendar')
        .query({ month: 7, year: 2026 })
        .set('Authorization', `Bearer ${user1Token}`);

      expect(res.statusCode).toBe(200);
      expect(res.body).toHaveLength(1);
      expect(res.body).toContain('2026-07-01');
    });

    it('should return 400 with INVALID_DATE_RANGE when month is missing', async () => {
      const res = await request(app)
        .get('/api/v1/calendar')
        .query({ year: 2026 })
        .set('Authorization', `Bearer ${user1Token}`);

      expect(res.statusCode).toBe(400);
      expect(res.body.errorCode).toBe('INVALID_DATE_RANGE');
    });

    it('should return 400 with INVALID_DATE_RANGE when month is invalid', async () => {
      const res = await request(app)
        .get('/api/v1/calendar')
        .query({ month: 13, year: 2026 })
        .set('Authorization', `Bearer ${user1Token}`);

      expect(res.statusCode).toBe(400);
      expect(res.body.errorCode).toBe('INVALID_DATE_RANGE');
    });

    it('should return 400 with INVALID_DATE_RANGE when year is missing', async () => {
      const res = await request(app)
        .get('/api/v1/calendar')
        .query({ month: 6 })
        .set('Authorization', `Bearer ${user1Token}`);

      expect(res.statusCode).toBe(400);
      expect(res.body.errorCode).toBe('INVALID_DATE_RANGE');
    });

    it('should return 401 when request is not authenticated', async () => {
      const res = await request(app)
        .get('/api/v1/calendar')
        .query({ month: 6, year: 2026 });

      expect(res.statusCode).toBe(401);
    });
  });
});
