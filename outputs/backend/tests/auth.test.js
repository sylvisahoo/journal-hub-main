import request from 'supertest';
import app from '../src/app.js';
import db from '../src/config/db.js';
import { initDatabase } from '../src/config/initDb.js';

describe('Auth Integration Tests', () => {
  beforeAll(async () => {
    // Re-initialize database schema for testing (do not seed, we will write custom tests)
    await initDatabase(false);
    await db.run('DELETE FROM User;');
  });

  afterAll(async () => {
    // Clean up connection
    await db.close();
  });

  beforeEach(async () => {
    // Clear User and EmailVerificationToken tables before each test
    await db.run('DELETE FROM EmailVerificationToken;');
    await db.run('DELETE FROM User;');
  });

  describe('POST /api/v1/auth/register', () => {
    const validUser = {
      fullName: 'John Doe',
      email: 'john@example.com',
      password: 'Password123!'
    };

    it('should successfully register a user with 201 Created', async () => {
      const res = await request(app)
        .post('/api/v1/auth/register')
        .send(validUser);

      expect(res.statusCode).toBe(201);
      expect(res.body).toHaveProperty('userId');
      expect(res.body).toHaveProperty('accountStatus', 'Pending');
      expect(res.body).toHaveProperty('message');

      // Check SQLite database
      const dbUser = await db.get('SELECT * FROM User WHERE email = ?;', [validUser.email]);
      expect(dbUser).toBeDefined();
      expect(dbUser.full_name).toBe(validUser.fullName);
      expect(dbUser.account_status).toBe('Pending');

      const dbToken = await db.get('SELECT * FROM EmailVerificationToken WHERE user_id = ?;', [dbUser.user_id]);
      expect(dbToken).toBeDefined();
      expect(dbToken.token).toBeDefined();
    });

    it('should fail with 400 REQUIRED_FIELD_MISSING if fullName is missing', async () => {
      const res = await request(app)
        .post('/api/v1/auth/register')
        .send({
          email: 'john@example.com',
          password: 'Password123!'
        });

      expect(res.statusCode).toBe(400);
      expect(res.body.errorCode).toBe('REQUIRED_FIELD_MISSING');
    });

    it('should fail with 400 REQUIRED_FIELD_MISSING if email is missing', async () => {
      const res = await request(app)
        .post('/api/v1/auth/register')
        .send({
          fullName: 'John Doe',
          password: 'Password123!'
        });

      expect(res.statusCode).toBe(400);
      expect(res.body.errorCode).toBe('REQUIRED_FIELD_MISSING');
    });

    it('should fail with 400 INVALID_EMAIL if email is invalid format', async () => {
      const res = await request(app)
        .post('/api/v1/auth/register')
        .send({
          fullName: 'John Doe',
          email: 'invalid-email-format',
          password: 'Password123!'
        });

      expect(res.statusCode).toBe(400);
      expect(res.body.errorCode).toBe('INVALID_EMAIL');
    });

    it('should fail with 400 WEAK_PASSWORD if password is less than 8 characters', async () => {
      const res = await request(app)
        .post('/api/v1/auth/register')
        .send({
          fullName: 'John Doe',
          email: 'john@example.com',
          password: 'weak'
        });

      expect(res.statusCode).toBe(400);
      expect(res.body.errorCode).toBe('WEAK_PASSWORD');
    });

    it('should fail with 409 DUPLICATE_EMAIL if email is already registered', async () => {
      // Register first user
      await request(app)
        .post('/api/v1/auth/register')
        .send(validUser);

      // Register same email again
      const res = await request(app)
        .post('/api/v1/auth/register')
        .send({
          fullName: 'Another User',
          email: validUser.email,
          password: 'Password123!'
        });

      expect(res.statusCode).toBe(409);
      expect(res.body.errorCode).toBe('DUPLICATE_EMAIL');
    });

    it('should fail with 409 DUPLICATE_EMAIL if email is already registered with different casing', async () => {
      // Register first user
      await request(app)
        .post('/api/v1/auth/register')
        .send(validUser);

      // Register same email with uppercase casing
      const res = await request(app)
        .post('/api/v1/auth/register')
        .send({
          fullName: 'Another User',
          email: 'JOHN@EXAMPLE.COM',
          password: 'Password123!'
        });

      expect(res.statusCode).toBe(409);
      expect(res.body.errorCode).toBe('DUPLICATE_EMAIL');
    });
  });

  describe('POST & GET /api/v1/auth/verify-email', () => {
    it('should successfully verify email with 200 OK', async () => {
      // 1. Register a user
      const registerRes = await request(app)
        .post('/api/v1/auth/register')
        .send({
          fullName: 'Jane Doe',
          email: 'jane@example.com',
          password: 'Password123!'
        });

      const userId = registerRes.body.userId;

      // 2. Fetch the token from DB
      const dbToken = await db.get('SELECT * FROM EmailVerificationToken WHERE user_id = ?;', [userId]);
      expect(dbToken).toBeDefined();

      // 3. Verify Email
      const res = await request(app)
        .post('/api/v1/auth/verify-email')
        .send({
          verificationToken: dbToken.token
        });

      expect(res.statusCode).toBe(200);
      expect(res.body.status).toBe('SUCCESS');

      // Verify User status updated in DB
      const dbUser = await db.get('SELECT * FROM User WHERE user_id = ?;', [userId]);
      expect(dbUser.account_status).toBe('Verified');

      // Verify token marked as used
      const dbTokenAfter = await db.get('SELECT * FROM EmailVerificationToken WHERE user_id = ?;', [userId]);
      expect(dbTokenAfter.verified_at).not.toBeNull();
    });

    it('should fail with 400 INVALID_TOKEN if token is invalid/not found', async () => {
      const res = await request(app)
        .post('/api/v1/auth/verify-email')
        .send({
          verificationToken: 'non-existent-token'
        });

      expect(res.statusCode).toBe(400);
      expect(res.body.errorCode).toBe('INVALID_TOKEN');
    });

    it('should fail with 410 TOKEN_EXPIRED if verification token has expired', async () => {
      // Manually seed expired token
      const userId = 'u-expired-test';
      await db.run(
        'INSERT INTO User (user_id, full_name, email, password_hash, account_status) VALUES (?, ?, ?, ?, ?);',
        [userId, 'Expired User', 'expired@example.com', 'hash', 'Pending']
      );

      const token = 'expired-token-12345';
      const expiredTime = new Date(Date.now() - 1000).toISOString(); // 1 second in the past
      await db.run(
        'INSERT INTO EmailVerificationToken (verification_id, user_id, token, expires_at) VALUES (?, ?, ?, ?);',
        ['v-expired-id', userId, token, expiredTime]
      );

      const res = await request(app)
        .post('/api/v1/auth/verify-email')
        .send({
          verificationToken: token
        });

      expect(res.statusCode).toBe(410);
      expect(res.body.errorCode).toBe('TOKEN_EXPIRED');
    });

    it('should successfully verify email with GET 200 OK and HTML response', async () => {
      // 1. Register a user
      const registerRes = await request(app)
        .post('/api/v1/auth/register')
        .send({
          fullName: 'Jane Doe',
          email: 'jane-get@example.com',
          password: 'Password123!'
        });

      const userId = registerRes.body.userId;

      // 2. Fetch the token from DB
      const dbToken = await db.get('SELECT * FROM EmailVerificationToken WHERE user_id = ?;', [userId]);
      expect(dbToken).toBeDefined();

      // 3. Verify Email via GET
      const res = await request(app)
        .get(`/api/v1/auth/verify-email?token=${dbToken.token}`);

      expect(res.statusCode).toBe(200);
      expect(res.text).toContain('Verification Successful');

      // Verify User status updated in DB
      const dbUser = await db.get('SELECT * FROM User WHERE user_id = ?;', [userId]);
      expect(dbUser.account_status).toBe('Verified');
    });

    it('should fail with GET 400 when token is missing', async () => {
      const res = await request(app)
        .get('/api/v1/auth/verify-email');

      expect(res.statusCode).toBe(400);
      expect(res.text).toContain('Verification token is missing');
    });

    it('should fail with GET 400 when token is invalid', async () => {
      const res = await request(app)
        .get('/api/v1/auth/verify-email?token=invalidtoken');

      expect(res.statusCode).toBe(400);
      expect(res.text).toContain('Verification Failed');
    });
  });
});
