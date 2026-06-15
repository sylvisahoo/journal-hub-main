import db from '../config/db.js';

export const sessionRepository = {
  async createSession(session) {
    const { sessionId, userId, accessToken, refreshToken, expiresAt } = session;
    const sql = `
      INSERT INTO UserSession (session_id, user_id, access_token, refresh_token, expires_at, created_at, is_active)
      VALUES (?, ?, ?, ?, ?, CURRENT_TIMESTAMP, 1);
    `;
    await db.run(sql, [sessionId, userId, accessToken, refreshToken, expiresAt]);
    return this.findById(sessionId);
  },

  async findById(sessionId) {
    return db.get('SELECT * FROM UserSession WHERE session_id = ?;', [sessionId]);
  },

  async findByToken(token) {
    return db.get('SELECT * FROM UserSession WHERE access_token = ? AND is_active = 1;', [token]);
  },

  async findByRefreshToken(token) {
    return db.get('SELECT * FROM UserSession WHERE refresh_token = ? AND is_active = 1;', [token]);
  },

  async invalidateSession(sessionId) {
    const sql = `
      UPDATE UserSession 
      SET is_active = 0 
      WHERE session_id = ?;
    `;
    await db.run(sql, [sessionId]);
    return this.findById(sessionId);
  },

  async invalidateAllUserSessions(userId) {
    const sql = `
      UPDATE UserSession 
      SET is_active = 0 
      WHERE user_id = ?;
    `;
    await db.run(sql, [userId]);
  }
};

export default sessionRepository;
