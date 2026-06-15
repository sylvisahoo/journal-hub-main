import db from '../config/db.js';

export const passwordResetRepository = {
  async createResetToken(record) {
    const { resetId, userId, token, expiresAt } = record;
    const sql = `
      INSERT INTO PasswordResetToken (reset_id, user_id, token, expires_at, created_at)
      VALUES (?, ?, ?, ?, CURRENT_TIMESTAMP);
    `;
    await db.run(sql, [resetId, userId, token, expiresAt]);
    return this.findById(resetId);
  },

  async findById(resetId) {
    return db.get('SELECT * FROM PasswordResetToken WHERE reset_id = ?;', [resetId]);
  },

  async findByToken(token) {
    return db.get('SELECT * FROM PasswordResetToken WHERE token = ? AND used_at IS NULL;', [token]);
  },

  async markTokenAsUsed(resetId) {
    const sql = `
      UPDATE PasswordResetToken 
      SET used_at = CURRENT_TIMESTAMP 
      WHERE reset_id = ?;
    `;
    await db.run(sql, [resetId]);
    return this.findById(resetId);
  }
};

export default passwordResetRepository;
