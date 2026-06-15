import request from 'supertest';
import app from '../src/app.js';
import db from '../src/config/db.js';
import { initDatabase } from '../src/config/initDb.js';
import bcrypt from 'bcrypt';
import jwt from 'jsonwebtoken';
import config from '../src/config/environment.js';

describe('Analytics Dashboard APIs (Module 9)', () => {
  let userToken;
  let userId = 'u-analytics-user';

  beforeAll(async () => {
    // Re-initialize database schema
    await initDatabase(false);
    await db.run('DELETE FROM User;');

    // Hash password
    const passwordHash = await bcrypt.hash('Password123!', 10);

    // Insert test user
    await db.run(
      'INSERT INTO User (user_id, full_name, email, password_hash, account_status) VALUES (?, ?, ?, ?, ?);',
      [userId, 'Analytics User', 'analyt@example.com', passwordHash, 'Verified']
    );

    // Generate JWT access token
    userToken = jwt.sign(
      { userId, email: 'analyt@example.com', fullName: 'Analytics User' },
      config.jwt.secret,
      { expiresIn: '15m' }
    );

    // Insert session
    const expiresAt = new Date(Date.now() + 15 * 60 * 1000).toISOString();
    await db.run(
      'INSERT INTO UserSession (session_id, user_id, access_token, refresh_token, expires_at, is_active) VALUES (?, ?, ?, ?, ?, ?);',
      ['sess-analyt', userId, userToken, 'refresh-analyt', expiresAt, 1]
    );
  });

  afterAll(async () => {
    await db.close();
  });

  it('should return 401 when accessing analytics unauthenticated', async () => {
    const res = await request(app).get('/api/v1/analytics');
    expect(res.statusCode).toBe(401);
  });

  describe('Calculations and Payload Verification', () => {
    beforeEach(async () => {
      // Clear entries before each test
      await db.run('DELETE FROM JournalEntry WHERE user_id = ?;', [userId]);
    });

    it('should return empty/zero analytics data if user has no journal entries', async () => {
      const res = await request(app)
        .get('/api/v1/analytics')
        .set('Authorization', `Bearer ${userToken}`);

      expect(res.statusCode).toBe(200);
      expect(res.body).toEqual({
        writingStreak: 0,
        totalEntries: 0,
        totalWords: 0,
        monthlyActivity: [],
        heatmapData: []
      });
    });

    it('should correctly calculate analytics stats and 3-day writing streak', async () => {
      // Insert 3 consecutive entries (e.g. 2026-06-09, 2026-06-10, 2026-06-11)
      await db.run(
        'INSERT INTO JournalEntry (journal_id, user_id, title, content, entry_date, word_count) VALUES (?, ?, ?, ?, ?, ?);',
        ['j-an-1', userId, 'Day 1', 'Content one.', '2026-06-11', 2] // 2 words
      );
      await db.run(
        'INSERT INTO JournalEntry (journal_id, user_id, title, content, entry_date, word_count) VALUES (?, ?, ?, ?, ?, ?);',
        ['j-an-2', userId, 'Day 2', 'Content two standard.', '2026-06-10', 3] // 3 words
      );
      await db.run(
        'INSERT INTO JournalEntry (journal_id, user_id, title, content, entry_date, word_count) VALUES (?, ?, ?, ?, ?, ?);',
        ['j-an-3', userId, 'Day 3', 'Content three word limit.', '2026-06-09', 4] // 4 words
      );

      const res = await request(app)
        .get('/api/v1/analytics')
        .set('Authorization', `Bearer ${userToken}`);

      expect(res.statusCode).toBe(200);
      expect(res.body.totalEntries).toBe(3);
      expect(res.body.totalWords).toBe(9);
      expect(res.body.writingStreak).toBe(3);

      // Monthly activity check (June 2026)
      expect(res.body.monthlyActivity).toHaveLength(1);
      expect(res.body.monthlyActivity[0]).toEqual({
        month: '2026-06',
        count: 3
      });

      // Heatmap check (3 distinct days)
      expect(res.body.heatmapData).toHaveLength(3);
      expect(res.body.heatmapData).toContainEqual({ date: '2026-06-09', count: 1 });
      expect(res.body.heatmapData).toContainEqual({ date: '2026-06-10', count: 1 });
      expect(res.body.heatmapData).toContainEqual({ date: '2026-06-11', count: 1 });
    });

    it('should detect a broken streak and reset correctly', async () => {
      // Insert entries with a gap (e.g. 2026-06-11 and 2026-06-09, missing 2026-06-10)
      await db.run(
        'INSERT INTO JournalEntry (journal_id, user_id, title, content, entry_date, word_count) VALUES (?, ?, ?, ?, ?, ?);',
        ['j-an-1', userId, 'Day 1', 'Content.', '2026-06-11', 1]
      );
      await db.run(
        'INSERT INTO JournalEntry (journal_id, user_id, title, content, entry_date, word_count) VALUES (?, ?, ?, ?, ?, ?);',
        ['j-an-3', userId, 'Day 3', 'Content.', '2026-06-09', 1]
      );

      const res = await request(app)
        .get('/api/v1/analytics')
        .set('Authorization', `Bearer ${userToken}`);

      expect(res.statusCode).toBe(200);
      expect(res.body.totalEntries).toBe(2);
      expect(res.body.writingStreak).toBe(1); // Only 1 consecutive day starting from 2026-06-11
    });
  });
});
