import request from 'supertest';
import app from '../src/app.js';
import db from '../src/config/db.js';
import { initDatabase } from '../src/config/initDb.js';
import bcrypt from 'bcrypt';
import jwt from 'jsonwebtoken';
import config from '../src/config/environment.js';

describe('Category and Tag Management APIs', () => {
  let user1Token;
  let user2Token;
  let user1Id = 'u-meta-user1';
  let user2Id = 'u-meta-user2';

  beforeAll(async () => {
    // Re-initialize database schema
    await initDatabase(false);
    await db.run('DELETE FROM User;');

    // Hash password
    const passwordHash = await bcrypt.hash('Password123!', 10);

    // Insert test users
    await db.run(
      'INSERT INTO User (user_id, full_name, email, password_hash, account_status) VALUES (?, ?, ?, ?, ?);',
      [user1Id, 'Meta User One', 'meta1@example.com', passwordHash, 'Verified']
    );

    await db.run(
      'INSERT INTO User (user_id, full_name, email, password_hash, account_status) VALUES (?, ?, ?, ?, ?);',
      [user2Id, 'Meta User Two', 'meta2@example.com', passwordHash, 'Verified']
    );

    // Generate JWT access tokens
    user1Token = jwt.sign(
      { userId: user1Id, email: 'meta1@example.com', fullName: 'Meta User One' },
      config.jwt.secret,
      { expiresIn: '15m' }
    );

    user2Token = jwt.sign(
      { userId: user2Id, email: 'meta2@example.com', fullName: 'Meta User Two' },
      config.jwt.secret,
      { expiresIn: '15m' }
    );

    // Insert active sessions into UserSession table
    const expiresAt = new Date(Date.now() + 15 * 60 * 1000).toISOString();
    await db.run(
      'INSERT INTO UserSession (session_id, user_id, access_token, refresh_token, expires_at, is_active) VALUES (?, ?, ?, ?, ?, ?);',
      ['s-meta1', user1Id, user1Token, 'refresh-token-m1', expiresAt, 1]
    );
    await db.run(
      'INSERT INTO UserSession (session_id, user_id, access_token, refresh_token, expires_at, is_active) VALUES (?, ?, ?, ?, ?, ?);',
      ['s-meta2', user2Id, user2Token, 'refresh-token-m2', expiresAt, 1]
    );
  });

  afterAll(async () => {
    await db.close();
  });

  describe('Categories APIs', () => {
    it('should successfully create a new category', async () => {
      const res = await request(app)
        .post('/api/v1/categories')
        .set('Authorization', `Bearer ${user1Token}`)
        .send({ categoryName: 'Health' });

      expect(res.statusCode).toBe(201);
      expect(res.body).toHaveProperty('categoryId');
      expect(res.body).toHaveProperty('categoryName', 'Health');

      const dbCategory = await db.get('SELECT * FROM Category WHERE category_id = ?;', [
        res.body.categoryId
      ]);
      expect(dbCategory).toBeDefined();
      expect(dbCategory.category_name).toBe('Health');
    });

    it('should retrieve categories list belonging to the user', async () => {
      const res = await request(app)
        .get('/api/v1/categories')
        .set('Authorization', `Bearer ${user1Token}`);

      expect(res.statusCode).toBe(200);
      expect(res.body.length).toBeGreaterThanOrEqual(1);
      expect(res.body[0]).toHaveProperty('categoryName');
    });

    it('should reject creation of duplicate category name per user with 409 DUPLICATE_CATEGORY', async () => {
      const res = await request(app)
        .post('/api/v1/categories')
        .set('Authorization', `Bearer ${user1Token}`)
        .send({ categoryName: 'Health' });

      expect(res.statusCode).toBe(409);
      expect(res.body.errorCode).toBe('DUPLICATE_CATEGORY');
    });

    it('should reject requests with empty category name with 400 REQUIRED_FIELD_MISSING', async () => {
      const res = await request(app)
        .post('/api/v1/categories')
        .set('Authorization', `Bearer ${user1Token}`)
        .send({ categoryName: '' });

      expect(res.statusCode).toBe(400);
      expect(res.body.errorCode).toBe('REQUIRED_FIELD_MISSING');
    });
  });

  describe('Tags APIs', () => {
    it('should successfully create a new tag', async () => {
      const res = await request(app)
        .post('/api/v1/tags')
        .set('Authorization', `Bearer ${user1Token}`)
        .send({ tagName: 'fitness' });

      expect(res.statusCode).toBe(201);
      expect(res.body).toHaveProperty('tagId');
      expect(res.body).toHaveProperty('tagName', 'fitness');

      const dbTag = await db.get('SELECT * FROM Tag WHERE tag_id = ?;', [res.body.tagId]);
      expect(dbTag).toBeDefined();
      expect(dbTag.tag_name).toBe('fitness');
    });

    it('should retrieve tags list belonging to the user', async () => {
      const res = await request(app)
        .get('/api/v1/tags')
        .set('Authorization', `Bearer ${user1Token}`);

      expect(res.statusCode).toBe(200);
      expect(res.body.length).toBeGreaterThanOrEqual(1);
      expect(res.body[0]).toHaveProperty('tagName');
    });

    it('should reject creation of duplicate tag name per user with 409 DUPLICATE_TAG', async () => {
      const res = await request(app)
        .post('/api/v1/tags')
        .set('Authorization', `Bearer ${user1Token}`)
        .send({ tagName: 'fitness' });

      expect(res.statusCode).toBe(409);
      expect(res.body.errorCode).toBe('DUPLICATE_TAG');
    });

    it('should reject requests with empty tag name with 400 REQUIRED_FIELD_MISSING', async () => {
      const res = await request(app)
        .post('/api/v1/tags')
        .set('Authorization', `Bearer ${user1Token}`)
        .send({ tagName: '' });

      expect(res.statusCode).toBe(400);
      expect(res.body.errorCode).toBe('REQUIRED_FIELD_MISSING');
    });
  });
});
