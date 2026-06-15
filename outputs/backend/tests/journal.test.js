import request from 'supertest';
import app from '../src/app.js';
import db from '../src/config/db.js';
import { initDatabase } from '../src/config/initDb.js';
import bcrypt from 'bcrypt';
import jwt from 'jsonwebtoken';
import config from '../src/config/environment.js';

describe('Journal Management APIs', () => {
  let user1Token;
  let user2Token;
  let user1Id = 'u-journal-user1';
  let user2Id = 'u-journal-user2';
  let categoryId = 'c-journal-test-cat';
  let tagId1 = 't-journal-test-tag1';
  let tagId2 = 't-journal-test-tag2';

  beforeAll(async () => {
    // Re-initialize database schema
    await initDatabase(false);
    await db.run('DELETE FROM User;');

    // Hash password
    const passwordHash = await bcrypt.hash('Password123!', 10);

    // Insert test users
    await db.run(
      'INSERT INTO User (user_id, full_name, email, password_hash, account_status) VALUES (?, ?, ?, ?, ?);',
      [user1Id, 'Journal User One', 'journal1@example.com', passwordHash, 'Verified']
    );

    await db.run(
      'INSERT INTO User (user_id, full_name, email, password_hash, account_status) VALUES (?, ?, ?, ?, ?);',
      [user2Id, 'Journal User Two', 'journal2@example.com', passwordHash, 'Verified']
    );

    // Seed test category
    await db.run(
      'INSERT INTO Category (category_id, user_id, category_name) VALUES (?, ?, ?);',
      [categoryId, user1Id, 'Life']
    );

    // Seed test tags
    await db.run(
      'INSERT INTO Tag (tag_id, user_id, tag_name) VALUES (?, ?, ?);',
      [tagId1, user1Id, 'gratitude']
    );
    await db.run(
      'INSERT INTO Tag (tag_id, user_id, tag_name) VALUES (?, ?, ?);',
      [tagId2, user1Id, 'reflection']
    );

    // Generate JWT access tokens
    user1Token = jwt.sign(
      { userId: user1Id, email: 'journal1@example.com', fullName: 'Journal User One' },
      config.jwt.secret,
      { expiresIn: '15m' }
    );

    user2Token = jwt.sign(
      { userId: user2Id, email: 'journal2@example.com', fullName: 'Journal User Two' },
      config.jwt.secret,
      { expiresIn: '15m' }
    );

    // Insert active sessions into UserSession table
    const expiresAt = new Date(Date.now() + 15 * 60 * 1000).toISOString();
    await db.run(
      'INSERT INTO UserSession (session_id, user_id, access_token, refresh_token, expires_at, is_active) VALUES (?, ?, ?, ?, ?, ?);',
      ['s-journal1', user1Id, user1Token, 'refresh-token-j1', expiresAt, 1]
    );
    await db.run(
      'INSERT INTO UserSession (session_id, user_id, access_token, refresh_token, expires_at, is_active) VALUES (?, ?, ?, ?, ?, ?);',
      ['s-journal2', user2Id, user2Token, 'refresh-token-j2', expiresAt, 1]
    );
  });

  afterAll(async () => {
    await db.close();
  });

  describe('POST /api/v1/journals', () => {
    it('should successfully create a new journal entry with tags and category', async () => {
      const res = await request(app)
        .post('/api/v1/journals')
        .set('Authorization', `Bearer ${user1Token}`)
        .send({
          title: 'My Day at the Park',
          content: 'The weather was beautiful and I walked for two hours. I felt very happy.',
          entryDate: '2026-06-11T12:00:00.000Z',
          categoryId: categoryId,
          tags: [tagId1, tagId2],
          isPrivate: true
        });

      expect(res.statusCode).toBe(201);
      expect(res.body).toHaveProperty('journalId');
      expect(res.body.title).toBe('My Day at the Park');
      expect(res.body.categoryId).toBe(categoryId);
      expect(res.body.tags).toContain(tagId1);
      expect(res.body.tags).toContain(tagId2);
      expect(res.body.wordCount).toBe(14); // "The weather was beautiful and I walked for two hours. I felt very happy." is 14 words
      expect(res.body.versionNumber).toBe(1);
    });

    it('should reject requests with empty content with 400 CONTENT_REQUIRED', async () => {
      const res = await request(app)
        .post('/api/v1/journals')
        .set('Authorization', `Bearer ${user1Token}`)
        .send({
          title: 'Empty Content Entry',
          content: '',
          entryDate: '2026-06-11T12:00:00.000Z'
        });

      expect(res.statusCode).toBe(400);
      expect(res.body.errorCode).toBe('CONTENT_REQUIRED');
    });

    it('should reject requests with invalid date format with 400 INVALID_DATE', async () => {
      const res = await request(app)
        .post('/api/v1/journals')
        .set('Authorization', `Bearer ${user1Token}`)
        .send({
          title: 'Invalid Date Entry',
          content: 'Some content here.',
          entryDate: 'not-a-date'
        });

      expect(res.statusCode).toBe(400);
      expect(res.body.errorCode).toBe('INVALID_DATE');
    });
  });

  describe('GET /api/v1/journals', () => {
    it('should successfully list active journal entries for authenticated user', async () => {
      const res = await request(app)
        .get('/api/v1/journals')
        .set('Authorization', `Bearer ${user1Token}`);

      expect(res.statusCode).toBe(200);
      expect(Array.isArray(res.body)).toBe(true);
      expect(res.body.length).toBeGreaterThanOrEqual(1);
      expect(res.body[0].userId).toBe(user1Id);
    });

    it('should filter entries by category', async () => {
      const res = await request(app)
        .get('/api/v1/journals')
        .query({ category: categoryId })
        .set('Authorization', `Bearer ${user1Token}`);

      expect(res.statusCode).toBe(200);
      expect(res.body.every((e) => e.categoryId === categoryId)).toBe(true);
    });

    it('should filter entries by keyword search in title or content', async () => {
      const res = await request(app)
        .get('/api/v1/journals')
        .query({ keyword: 'weather' })
        .set('Authorization', `Bearer ${user1Token}`);

      expect(res.statusCode).toBe(200);
      expect(res.body.length).toBe(1);
      expect(res.body[0].title).toBe('My Day at the Park');
    });

    it('should filter entries by tag', async () => {
      const res = await request(app)
        .get('/api/v1/journals')
        .query({ tag: tagId1 })
        .set('Authorization', `Bearer ${user1Token}`);

      expect(res.statusCode).toBe(200);
      expect(res.body.length).toBeGreaterThanOrEqual(1);
      expect(res.body.every((e) => e.tags.includes(tagId1))).toBe(true);
    });

    it('should filter entries by date range', async () => {
      const res = await request(app)
        .get('/api/v1/journals')
        .query({ startDate: '2026-06-10T00:00:00.000Z', endDate: '2026-06-12T00:00:00.000Z' })
        .set('Authorization', `Bearer ${user1Token}`);

      expect(res.statusCode).toBe(200);
      expect(res.body.length).toBeGreaterThanOrEqual(1);
      expect(res.body.every((e) => {
        const date = new Date(e.entryDate);
        return date >= new Date('2026-06-10') && date <= new Date('2026-06-12T23:59:59.999Z');
      })).toBe(true);
    });
  });

  describe('GET /api/v1/journals/:journalId', () => {
    let testJournalId;

    beforeAll(async () => {
      const res = await request(app)
        .post('/api/v1/journals')
        .set('Authorization', `Bearer ${user1Token}`)
        .send({
          title: 'Detail View Test',
          content: 'Details details details.',
          entryDate: '2026-06-11T12:00:00.000Z'
        });
      testJournalId = res.body.journalId;
    });

    it('should retrieve detail view of owned journal entry', async () => {
      const res = await request(app)
        .get(`/api/v1/journals/${testJournalId}`)
        .set('Authorization', `Bearer ${user1Token}`);

      expect(res.statusCode).toBe(200);
      expect(res.body.journalId).toBe(testJournalId);
      expect(res.body.title).toBe('Detail View Test');
    });

    it('should reject access to another user\'s journal entry with 403 ACCESS_DENIED', async () => {
      const res = await request(app)
        .get(`/api/v1/journals/${testJournalId}`)
        .set('Authorization', `Bearer ${user2Token}`);

      expect(res.statusCode).toBe(403);
      expect(res.body.errorCode).toBe('ACCESS_DENIED');
    });

    it('should return 404 ENTRY_NOT_FOUND for non-existent entry ID', async () => {
      const res = await request(app)
        .get('/api/v1/journals/j-nonexistent')
        .set('Authorization', `Bearer ${user1Token}`);

      expect(res.statusCode).toBe(404);
      expect(res.body.errorCode).toBe('ENTRY_NOT_FOUND');
    });
  });

  describe('PUT /api/v1/journals/:journalId', () => {
    let editJournalId;

    beforeEach(async () => {
      // Create clean entry to edit
      const res = await request(app)
        .post('/api/v1/journals')
        .set('Authorization', `Bearer ${user1Token}`)
        .send({
          title: 'Before Edit Title',
          content: 'Original Content.',
          entryDate: '2026-06-11T12:00:00.000Z'
        });
      editJournalId = res.body.journalId;
    });

    it('should successfully edit journal entry and increment version number', async () => {
      const res = await request(app)
        .put(`/api/v1/journals/${editJournalId}`)
        .set('Authorization', `Bearer ${user1Token}`)
        .send({
          title: 'After Edit Title',
          content: 'Updated Content is longer.',
          versionNumber: 1
        });

      expect(res.statusCode).toBe(200);
      expect(res.body.title).toBe('After Edit Title');
      expect(res.body.content).toBe('Updated Content is longer.');
      expect(res.body.versionNumber).toBe(2);

      // Verify version history record in database
      const dbHistory = await db.all(
        'SELECT * FROM JournalEntryVersion WHERE journal_id = ? ORDER BY version_number ASC;',
        [editJournalId]
      );
      expect(dbHistory.length).toBe(1);
      expect(dbHistory[0].version_number).toBe(1);
      expect(dbHistory[0].title).toBe('Before Edit Title');
      expect(dbHistory[0].content).toBe('Original Content.');
    });

    it('should reject edits with version mismatch producing 409 VERSION_CONFLICT', async () => {
      const res = await request(app)
        .put(`/api/v1/journals/${editJournalId}`)
        .set('Authorization', `Bearer ${user1Token}`)
        .send({
          title: 'Conflict Edit Title',
          content: 'Conflict Content.',
          versionNumber: 99 // Wrong version number
        });

      expect(res.statusCode).toBe(409);
      expect(res.body.errorCode).toBe('VERSION_CONFLICT');
    });

    it('should reject editing another user\'s journal entry with 403 ACCESS_DENIED', async () => {
      const res = await request(app)
        .put(`/api/v1/journals/${editJournalId}`)
        .set('Authorization', `Bearer ${user2Token}`)
        .send({
          title: 'Hacked Edit Title',
          content: 'Hacked Content.',
          versionNumber: 1
        });

      expect(res.statusCode).toBe(403);
      expect(res.body.errorCode).toBe('ACCESS_DENIED');
    });
  });

  describe('DELETE /api/v1/journals/:journalId', () => {
    let deleteJournalId;

    beforeEach(async () => {
      const res = await request(app)
        .post('/api/v1/journals')
        .set('Authorization', `Bearer ${user1Token}`)
        .send({
          title: 'To Be Deleted',
          content: 'Going soon.',
          entryDate: '2026-06-11T12:00:00.000Z'
        });
      deleteJournalId = res.body.journalId;
    });

    it('should soft delete journal entry (setting deleted_at and hiding from listings)', async () => {
      const resDelete = await request(app)
        .delete(`/api/v1/journals/${deleteJournalId}`)
        .set('Authorization', `Bearer ${user1Token}`);

      expect(resDelete.statusCode).toBe(200);
      expect(resDelete.body.message).toContain('soft deleted');

      // Verify hidden from listings
      const resList = await request(app)
        .get('/api/v1/journals')
        .set('Authorization', `Bearer ${user1Token}`);
      
      expect(resList.body.some((e) => e.journalId === deleteJournalId)).toBe(false);

      // Verify still exists in database
      const dbRow = await db.get('SELECT * FROM JournalEntry WHERE journal_id = ?;', [
        deleteJournalId
      ]);
      expect(dbRow).toBeDefined();
      expect(dbRow.deleted_at).not.toBeNull();
    });

    it('should permanently delete entry if permanent=true query is provided', async () => {
      const resDelete = await request(app)
        .delete(`/api/v1/journals/${deleteJournalId}`)
        .query({ permanent: 'true' })
        .set('Authorization', `Bearer ${user1Token}`);

      expect(resDelete.statusCode).toBe(200);
      expect(resDelete.body.message).toContain('permanently deleted');

      // Verify removed from database
      const dbRow = await db.get('SELECT * FROM JournalEntry WHERE journal_id = ?;', [
        deleteJournalId
      ]);
      expect(dbRow).toBeUndefined();
    });

    it('should reject deletion of another user\'s journal entry with 403 ACCESS_DENIED', async () => {
      const resDelete = await request(app)
        .delete(`/api/v1/journals/${deleteJournalId}`)
        .set('Authorization', `Bearer ${user2Token}`);

      expect(resDelete.statusCode).toBe(403);
      expect(resDelete.body.errorCode).toBe('ACCESS_DENIED');
    });
  });
});
