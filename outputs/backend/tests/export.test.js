import request from 'supertest';
import fs from 'fs';
import path from 'path';
import app from '../src/app.js';
import db from '../src/config/db.js';
import { initDatabase } from '../src/config/initDb.js';
import bcrypt from 'bcrypt';
import jwt from 'jsonwebtoken';
import config from '../src/config/environment.js';

const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

const waitForStatus = async (exportId, statuses, maxMs = 3000) => {
  const start = Date.now();
  while (Date.now() - start < maxMs) {
    const job = await db.get('SELECT export_status FROM ExportRequest WHERE export_id = ?;', [exportId]);
    if (job && statuses.includes(job.export_status)) {
      return job.export_status;
    }
    await sleep(50);
  }
  const job = await db.get('SELECT export_status FROM ExportRequest WHERE export_id = ?;', [exportId]);
  return job ? job.export_status : null;
};

describe('Data Export APIs (Module 10)', () => {
  let user1Token;
  let user2Token;
  let user1Id = 'u-export-user1';
  let user2Id = 'u-export-user2';
  let journalId1 = 'j-export-1';
  let journalId2 = 'j-export-2';

  beforeAll(async () => {
    // Re-initialize database schema
    await initDatabase(false);
    await db.run('DELETE FROM User;');

    // Hash password
    const passwordHash = await bcrypt.hash('Password123!', 10);

    // Insert test users
    await db.run(
      'INSERT INTO User (user_id, full_name, email, password_hash, account_status) VALUES (?, ?, ?, ?, ?);',
      [user1Id, 'User One', 'export_u1@example.com', passwordHash, 'Verified']
    );

    await db.run(
      'INSERT INTO User (user_id, full_name, email, password_hash, account_status) VALUES (?, ?, ?, ?, ?);',
      [user2Id, 'User Two', 'export_u2@example.com', passwordHash, 'Verified']
    );

    // Generate JWT access tokens
    user1Token = jwt.sign(
      { userId: user1Id, email: 'export_u1@example.com', fullName: 'User One' },
      config.jwt.secret,
      { expiresIn: '15m' }
    );

    user2Token = jwt.sign(
      { userId: user2Id, email: 'export_u2@example.com', fullName: 'User Two' },
      config.jwt.secret,
      { expiresIn: '15m' }
    );

    // Insert active sessions
    const expiresAt = new Date(Date.now() + 15 * 60 * 1000).toISOString();
    await db.run(
      'INSERT INTO UserSession (session_id, user_id, access_token, refresh_token, expires_at, is_active) VALUES (?, ?, ?, ?, ?, ?);',
      ['sess-export-1', user1Id, user1Token, 'refresh-export-1', expiresAt, 1]
    );
    await db.run(
      'INSERT INTO UserSession (session_id, user_id, access_token, refresh_token, expires_at, is_active) VALUES (?, ?, ?, ?, ?, ?);',
      ['sess-export-2', user2Id, user2Token, 'refresh-export-2', expiresAt, 1]
    );

    // Insert active journal entries
    await db.run(
      'INSERT INTO JournalEntry (journal_id, user_id, title, content, entry_date, word_count, is_private) VALUES (?, ?, ?, ?, ?, ?, ?);',
      [journalId1, user1Id, 'User 1 Journal 1', 'Content for journal 1 which is private.', '2026-06-11', 7, 1]
    );

    await db.run(
      'INSERT INTO JournalEntry (journal_id, user_id, title, content, entry_date, word_count, is_private) VALUES (?, ?, ?, ?, ?, ?, ?);',
      [journalId2, user1Id, 'User 1 Journal 2', 'Content for journal 2 which is public.', '2026-06-12', 7, 0]
    );
  });

  afterAll(async () => {
    await db.close();
  });

  describe('POST /api/v1/export', () => {
    it('should successfully trigger an export job and return 202 Accepted', async () => {
      const res = await request(app)
        .post('/api/v1/export')
        .set('Authorization', `Bearer ${user1Token}`)
        .send({ format: 'PDF' });

      expect(res.statusCode).toBe(202);
      expect(res.body).toHaveProperty('exportId');
      expect(res.body).toHaveProperty('status', 'Pending');
      const exportId = res.body.exportId;

      // Verify db request row exists
      const job = await db.get('SELECT * FROM ExportRequest WHERE export_id = ?;', [exportId]);
      expect(job).toBeDefined();
      expect(job.export_format).toBe('PDF');
      expect(['Pending', 'Processing']).toContain(job.export_status);

      // Verify audit trail was logged
      const audit = await db.get(
        "SELECT * FROM AuditLog WHERE entity_id = ? AND action_type = 'Export';",
        [exportId]
      );
      expect(audit).toBeDefined();
      expect(audit.user_id).toBe(user1Id);

      // Wait for background async queue to complete
      await waitForStatus(exportId, ['Completed', 'Failed']);

      // Verify db request row has transitioned to Completed
      const completedJob = await db.get('SELECT * FROM ExportRequest WHERE export_id = ?;', [exportId]);
      expect(completedJob.export_status).toBe('Completed');
      expect(completedJob.completed_at).not.toBeNull();

      // Verify file is stored on disk
      const exportsDir = path.join(process.cwd(), 'public/exports');
      const filePath = path.join(exportsDir, `journal_export_${exportId}.pdf`);
      expect(fs.existsSync(filePath)).toBe(true);

      const fileContent = fs.readFileSync(filePath, 'utf8');
      expect(fileContent).toContain('%PDF');

      // Verify static download URL access
      const downloadRes = await request(app).get(`/exports/journal_export_${exportId}.pdf`);
      expect(downloadRes.statusCode).toBe(200);
      expect(downloadRes.body.toString()).toContain('%PDF');

      // Verify database file entry
      const fileRecord = await db.get('SELECT * FROM ExportFile WHERE export_id = ?;', [exportId]);
      expect(fileRecord).toBeDefined();
      expect(fileRecord.download_url).toContain(`/exports/journal_export_${exportId}.pdf`);

      // Verify live in-app notification exists
      const notification = await db.get(
        "SELECT * FROM Notification WHERE user_id = ? AND title = 'Export Completed' ORDER BY created_at DESC LIMIT 1;",
        [user1Id]
      );
      expect(notification).toBeDefined();
      expect(notification.message).toContain(exportId.substring(exportId.length - 5));
    });

    it('should successfully trigger a JSON export job', async () => {
      const res = await request(app)
        .post('/api/v1/export')
        .set('Authorization', `Bearer ${user1Token}`)
        .send({ format: 'JSON' });

      expect(res.statusCode).toBe(202);
      const exportId = res.body.exportId;

      await waitForStatus(exportId, ['Completed', 'Failed']);

      const exportsDir = path.join(process.cwd(), 'public/exports');
      const filePath = path.join(exportsDir, `journal_export_${exportId}.json`);
      expect(fs.existsSync(filePath)).toBe(true);

      const fileContent = fs.readFileSync(filePath, 'utf8');
      const parsed = JSON.parse(fileContent);
      expect(Array.isArray(parsed)).toBe(true);
      expect(parsed.length).toBeGreaterThanOrEqual(1);
      expect(parsed[0]).toHaveProperty('title');
      expect(parsed[0]).toHaveProperty('content');
    });

    it('should reject invalid formats with 400 INVALID_EXPORT_FORMAT', async () => {
      const res = await request(app)
        .post('/api/v1/export')
        .set('Authorization', `Bearer ${user1Token}`)
        .send({ format: 'HTML' });

      expect(res.statusCode).toBe(400);
      expect(res.body.errorCode).toBe('INVALID_EXPORT_FORMAT');
    });

    it('should reject unauthenticated requests with 401', async () => {
      const res = await request(app).post('/api/v1/export').send({ format: 'DOCX' });
      expect(res.statusCode).toBe(401);
    });
  });

  describe('GET /api/v1/export/:exportId', () => {
    let activeExportId;

    beforeAll(async () => {
      const job = await db.get('SELECT export_id FROM ExportRequest WHERE user_id = ? LIMIT 1;', [user1Id]);
      activeExportId = job.export_id;
    });

    it('should return export status and download URL if completed', async () => {
      const res = await request(app)
        .get(`/api/v1/export/${activeExportId}`)
        .set('Authorization', `Bearer ${user1Token}`);

      expect(res.statusCode).toBe(200);
      expect(res.body.exportId).toBe(activeExportId);
      expect(res.body.status).toBe('Completed');
      expect(res.body.downloadUrl).toContain(`/exports/journal_export_${activeExportId}.pdf`);
    });

    it('should reject status queries from non-owners with 403 ACCESS_DENIED', async () => {
      const res = await request(app)
        .get(`/api/v1/export/${activeExportId}`)
        .set('Authorization', `Bearer ${user2Token}`);

      expect(res.statusCode).toBe(403);
      expect(res.body.errorCode).toBe('ACCESS_DENIED');
    });

    it('should return 404 for a nonexistent job', async () => {
      const res = await request(app)
        .get('/api/v1/export/exp-nonexistent')
        .set('Authorization', `Bearer ${user1Token}`);

      if (res.statusCode !== 404) {
        console.log('DEBUG nonexistent job response:', res.statusCode, res.body);
      }
      expect(res.statusCode).toBe(404);
      expect(res.body.errorCode).toBe('EXPORT_NOT_FOUND');
    });
  });

  describe('GET /api/v1/export', () => {
    it('should successfully list previous export requests for the user', async () => {
      const res = await request(app)
        .get('/api/v1/export')
        .set('Authorization', `Bearer ${user1Token}`);

      expect(res.statusCode).toBe(200);
      expect(Array.isArray(res.body)).toBe(true);
      expect(res.body.length).toBeGreaterThanOrEqual(1);

      const job = res.body[0];
      expect(job).toHaveProperty('exportId');
      expect(job).toHaveProperty('status');
      expect(job).toHaveProperty('format');
      expect(job).toHaveProperty('requestedAt');
      expect(job.userId).toBe(user1Id);
    });

    it('should return empty list if user has no export requests', async () => {
      const res = await request(app)
        .get('/api/v1/export')
        .set('Authorization', `Bearer ${user2Token}`);

      expect(res.statusCode).toBe(200);
      expect(Array.isArray(res.body)).toBe(true);
      expect(res.body.length).toBe(0);
    });
  });

  describe('Simulation of failures and POST /api/v1/export/:exportId/retry', () => {
    let failedExportId;
    let failTriggerJournalId = 'j-export-failure-trigger';

    beforeAll(async () => {
      // Add a journal entry containing 'trigger-export-failure' to simulate failure
      await db.run(
        'INSERT INTO JournalEntry (journal_id, user_id, title, content, entry_date, word_count) VALUES (?, ?, ?, ?, ?, ?);',
        [failTriggerJournalId, user1Id, 'Failure Test', 'Let us trigger-export-failure now.', '2026-06-12', 5]
      );
    });

    it('should simulate background generation failure and update job to Failed', async () => {
      const triggerRes = await request(app)
        .post('/api/v1/export')
        .set('Authorization', `Bearer ${user1Token}`)
        .send({ format: 'DOCX' });

      expect(triggerRes.statusCode).toBe(202);
      failedExportId = triggerRes.body.exportId;

      // Wait for background async queue to complete
      await waitForStatus(failedExportId, ['Completed', 'Failed']);

      // Verify db request row has transitioned to Failed
      const failedJob = await db.get('SELECT * FROM ExportRequest WHERE export_id = ?;', [failedExportId]);
      expect(failedJob.export_status).toBe('Failed');

      // Verify live in-app notification of failure exists
      const notification = await db.get(
        "SELECT * FROM Notification WHERE user_id = ? AND title = 'Export Failed' ORDER BY created_at DESC LIMIT 1;",
        [user1Id]
      );
      expect(notification).toBeDefined();
    });

    it('should reject retrying another user failed job with 403 ACCESS_DENIED', async () => {
      const res = await request(app)
        .post(`/api/v1/export/${failedExportId}/retry`)
        .set('Authorization', `Bearer ${user2Token}`);

      expect(res.statusCode).toBe(403);
      expect(res.body.errorCode).toBe('ACCESS_DENIED');
    });

    it('should successfully retry own failed export job', async () => {
      // 1. Remove/update the failure-trigger journal entry so background retry succeeds
      await db.run('DELETE FROM JournalEntry WHERE journal_id = ?;', [failTriggerJournalId]);

      // 2. Post retry request
      const retryRes = await request(app)
        .post(`/api/v1/export/${failedExportId}/retry`)
        .set('Authorization', `Bearer ${user1Token}`);

      expect(retryRes.statusCode).toBe(202);
      expect(retryRes.body.exportId).toBe(failedExportId);
      expect(retryRes.body.status).toBe('Pending');

      // 3. Verify audit log registered ExportRetry
      const audit = await db.get(
        "SELECT * FROM AuditLog WHERE entity_id = ? AND action_type = 'ExportRetry';",
        [failedExportId]
      );
      expect(audit).toBeDefined();

      // 4. Wait for retry processing
      await waitForStatus(failedExportId, ['Completed', 'Failed']);

      // 5. Verify status has transitioned to Completed
      const completedJob = await db.get('SELECT * FROM ExportRequest WHERE export_id = ?;', [failedExportId]);
      expect(completedJob.export_status).toBe('Completed');

      // 6. Verify file exists on disk
      const exportsDir = path.join(process.cwd(), 'public/exports');
      const filePath = path.join(exportsDir, `journal_export_${failedExportId}.docx`);
      expect(fs.existsSync(filePath)).toBe(true);
    });
  });
});
