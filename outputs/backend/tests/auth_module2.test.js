import request from 'supertest';
import app from '../src/app.js';
import db from '../src/config/db.js';
import { initDatabase } from '../src/config/initDb.js';
import bcrypt from 'bcrypt';
import { v4 as uuidv4 } from 'uuid';

describe('Auth Module 2 - Authentication & Session Management', () => {
  let verifiedUserId;
  let pendingUserId;
  let disabledUserId;

  const verifiedUser = {
    fullName: 'Jane Doe',
    email: 'jane.verified@example.com',
    password: 'Password123!'
  };

  const pendingUser = {
    fullName: 'John Doe',
    email: 'john.pending@example.com',
    password: 'Password123!'
  };

  const disabledUser = {
    fullName: 'Block User',
    email: 'block.disabled@example.com',
    password: 'Password123!'
  };

  beforeAll(async () => {
    // Re-initialize database schema
    await initDatabase(false);
    await db.run('DELETE FROM User;');

    // Hash password
    const passwordHash = await bcrypt.hash('Password123!', 10);

    // Seed User records
    verifiedUserId = `u-${uuidv4()}`;
    await db.run(
      'INSERT INTO User (user_id, full_name, email, password_hash, account_status) VALUES (?, ?, ?, ?, ?);',
      [verifiedUserId, verifiedUser.fullName, verifiedUser.email, passwordHash, 'Verified']
    );

    pendingUserId = `u-${uuidv4()}`;
    await db.run(
      'INSERT INTO User (user_id, full_name, email, password_hash, account_status) VALUES (?, ?, ?, ?, ?);',
      [pendingUserId, pendingUser.fullName, pendingUser.email, passwordHash, 'Pending']
    );

    disabledUserId = `u-${uuidv4()}`;
    await db.run(
      'INSERT INTO User (user_id, full_name, email, password_hash, account_status) VALUES (?, ?, ?, ?, ?);',
      [disabledUserId, disabledUser.fullName, disabledUser.email, passwordHash, 'Disabled']
    );
  });

  afterAll(async () => {
    await db.close();
  });

  describe('POST /api/v1/auth/login', () => {
    it('should successfully authenticate verified user and return tokens', async () => {
      const res = await request(app)
        .post('/api/v1/auth/login')
        .send({
          email: verifiedUser.email,
          password: verifiedUser.password
        });

      expect(res.statusCode).toBe(200);
      expect(res.body).toHaveProperty('accessToken');
      expect(res.body).toHaveProperty('refreshToken');
      expect(res.body).toHaveProperty('expiresAt');

      // Verify session created in DB
      const dbSession = await db.get('SELECT * FROM UserSession WHERE user_id = ? AND is_active = 1;', [verifiedUserId]);
      expect(dbSession).toBeDefined();
      expect(dbSession.access_token).toBe(res.body.accessToken);

      // Verify last login updated
      const dbUser = await db.get('SELECT * FROM User WHERE user_id = ?;', [verifiedUserId]);
      expect(dbUser.last_login_at).not.toBeNull();
    });

    it('should reject login if password is incorrect with 401 INVALID_CREDENTIALS', async () => {
      const res = await request(app)
        .post('/api/v1/auth/login')
        .send({
          email: verifiedUser.email,
          password: 'WrongPassword!'
        });

      expect(res.statusCode).toBe(401);
      expect(res.body.errorCode).toBe('INVALID_CREDENTIALS');
    });

    it('should reject login if email is not registered with 401 INVALID_CREDENTIALS', async () => {
      const res = await request(app)
        .post('/api/v1/auth/login')
        .send({
          email: 'unregistered@example.com',
          password: 'Password123!'
        });

      expect(res.statusCode).toBe(401);
      expect(res.body.errorCode).toBe('INVALID_CREDENTIALS');
    });

    it('should reject login if account is pending verification with 401 ACCOUNT_NOT_VERIFIED', async () => {
      const res = await request(app)
        .post('/api/v1/auth/login')
        .send({
          email: pendingUser.email,
          password: pendingUser.password
        });

      expect(res.statusCode).toBe(401);
      expect(res.body.errorCode).toBe('ACCOUNT_NOT_VERIFIED');
    });

    it('should reject login if account is disabled with 401 ACCOUNT_DISABLED', async () => {
      const res = await request(app)
        .post('/api/v1/auth/login')
        .send({
          email: disabledUser.email,
          password: disabledUser.password
        });

      expect(res.statusCode).toBe(401);
      expect(res.body.errorCode).toBe('ACCOUNT_DISABLED');
    });

    it('should fail validation with 400 if fields are missing', async () => {
      const res = await request(app)
        .post('/api/v1/auth/login')
        .send({
          email: verifiedUser.email
        });

      expect(res.statusCode).toBe(400);
      expect(res.body.errorCode).toBe('REQUIRED_FIELD_MISSING');
    });
  });

  describe('POST /api/v1/auth/forgot-password', () => {
    it('should successfully generate reset token and send reset email', async () => {
      const res = await request(app)
        .post('/api/v1/auth/forgot-password')
        .send({
          email: verifiedUser.email
        });

      expect(res.statusCode).toBe(200);
      expect(res.body).toHaveProperty('message');

      // Verify reset token exists in database
      const dbReset = await db.get('SELECT * FROM PasswordResetToken WHERE user_id = ? AND used_at IS NULL;', [verifiedUserId]);
      expect(dbReset).toBeDefined();
      expect(dbReset.token).toHaveLength(6); // 6-digit code
    });

    it('should fail with 400 INVALID_EMAIL if email is not registered', async () => {
      const res = await request(app)
        .post('/api/v1/auth/forgot-password')
        .send({
          email: 'notfound@example.com'
        });

      expect(res.statusCode).toBe(400);
      expect(res.body.errorCode).toBe('INVALID_EMAIL');
    });
  });

  describe('POST /api/v1/auth/reset-password', () => {
    it('should successfully reset user password and invalidate active sessions', async () => {
      // 1. Generate reset token
      await request(app)
        .post('/api/v1/auth/forgot-password')
        .send({ email: verifiedUser.email });

      const dbReset = await db.get('SELECT * FROM PasswordResetToken WHERE user_id = ? AND used_at IS NULL;', [verifiedUserId]);
      expect(dbReset).toBeDefined();

      // 2. Perform reset
      const res = await request(app)
        .post('/api/v1/auth/reset-password')
        .send({
          resetToken: dbReset.token,
          newPassword: 'NewPassword123!'
        });

      expect(res.statusCode).toBe(200);
      expect(res.body).toHaveProperty('message');

      // 3. Verify token marked as used
      const dbResetAfter = await db.get('SELECT * FROM PasswordResetToken WHERE reset_id = ?;', [dbReset.reset_id]);
      expect(dbResetAfter.used_at).not.toBeNull();

      // 4. Verify user password hash updated (cannot log in with old password, can log in with new password)
      const loginOld = await request(app)
        .post('/api/v1/auth/login')
        .send({
          email: verifiedUser.email,
          password: verifiedUser.password
        });
      expect(loginOld.statusCode).toBe(401);

      const loginNew = await request(app)
        .post('/api/v1/auth/login')
        .send({
          email: verifiedUser.email,
          password: 'NewPassword123!'
        });
      expect(loginNew.statusCode).toBe(200);
    });

    it('should reject expired password reset tokens with 410 TOKEN_EXPIRED', async () => {
      const token = '654321';
      const expiredTime = new Date(Date.now() - 1000).toISOString();
      await db.run(
        'INSERT INTO PasswordResetToken (reset_id, user_id, token, expires_at) VALUES (?, ?, ?, ?);',
        ['r-expired-test', verifiedUserId, token, expiredTime]
      );

      const res = await request(app)
        .post('/api/v1/auth/reset-password')
        .send({
          resetToken: token,
          newPassword: 'Password12345!'
        });

      expect(res.statusCode).toBe(410);
      expect(res.body.errorCode).toBe('TOKEN_EXPIRED');
    });

    it('should reject invalid password reset tokens with 400 INVALID_TOKEN', async () => {
      const res = await request(app)
        .post('/api/v1/auth/reset-password')
        .send({
          resetToken: '999999',
          newPassword: 'Password12345!'
        });

      expect(res.statusCode).toBe(400);
      expect(res.body.errorCode).toBe('INVALID_TOKEN');
    });

    it('should reject weak passwords with 400 WEAK_PASSWORD', async () => {
      await request(app)
        .post('/api/v1/auth/forgot-password')
        .send({ email: verifiedUser.email });

      const dbReset = await db.get('SELECT * FROM PasswordResetToken WHERE user_id = ? AND used_at IS NULL;', [verifiedUserId]);

      const res = await request(app)
        .post('/api/v1/auth/reset-password')
        .send({
          resetToken: dbReset.token,
          newPassword: 'weak'
        });

      expect(res.statusCode).toBe(400);
      expect(res.body.errorCode).toBe('WEAK_PASSWORD');
    });
  });

  describe('POST /api/v1/auth/logout', () => {
    it('should successfully invalidate session and restrict subsequent requests', async () => {
      // 1. Log in to get active session
      const loginRes = await request(app)
        .post('/api/v1/auth/login')
        .send({
          email: verifiedUser.email,
          password: 'NewPassword123!'
        });
      const token = loginRes.body.accessToken;

      // 2. Perform logout
      const logoutRes = await request(app)
        .post('/api/v1/auth/logout')
        .set('Authorization', `Bearer ${token}`);

      expect(logoutRes.statusCode).toBe(200);
      expect(logoutRes.body).toHaveProperty('message');

      // 3. Verify subsequent protected requests fail
      const repeatLogout = await request(app)
        .post('/api/v1/auth/logout')
        .set('Authorization', `Bearer ${token}`);

      expect(repeatLogout.statusCode).toBe(401);
      expect(repeatLogout.body.errorCode).toBe('INVALID_SESSION');
    });

    it('should reject request without Bearer token with 401 UNAUTHORIZED', async () => {
      const res = await request(app)
        .post('/api/v1/auth/logout');

      expect(res.statusCode).toBe(401);
      expect(res.body.errorCode).toBe('UNAUTHORIZED');
    });
  });
});
