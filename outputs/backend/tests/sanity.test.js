import request from 'supertest';
import app from '../src/app.js';
import db from '../src/config/db.js';

describe('Sanity & Configuration Tests', () => {
  afterAll(async () => {
    // Close SQLite database to prevent Jest hanging
    await db.close();
  });

  describe('GET /api/v1/health', () => {
    it('should return 200 OK with the health check details', async () => {
      const res = await request(app).get('/api/v1/health');
      expect(res.statusCode).toBe(200);
      expect(res.body).toHaveProperty('status', 'OK');
      expect(res.body).toHaveProperty('timestamp');
      expect(res.body).toHaveProperty('message', 'Journal Hub API service is active');
    });
  });

  describe('GET /api/v1/undefined-route-check', () => {
    it('should return 404 NOT_FOUND and match the standard error response contract', async () => {
      const res = await request(app).get('/api/v1/undefined-route-check');
      expect(res.statusCode).toBe(404);
      expect(res.body).toHaveProperty('errorCode', 'NOT_FOUND');
      expect(res.body).toHaveProperty('message', 'Requested resource not found');
      expect(res.body).toHaveProperty('timestamp');
      expect(res.body).toHaveProperty('requestId');
    });
  });
});
