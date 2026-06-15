import db from '../config/db.js';

export const verificationRepository = {
  async createToken(tokenRecord) {
    const { verificationId, userId, token, expiresAt } = tokenRecord;
    const sql = `
      INSERT INTO EmailVerificationToken (verification_id, user_id, token, expires_at, created_at)
      VALUES (?, ?, ?, ?, CURRENT_TIMESTAMP);
    `;
    await db.run(sql, [verificationId, userId, token, expiresAt]);
    return this.findById(verificationId);
  },

  async findById(verificationId) {
    return db.get('SELECT * FROM EmailVerificationToken WHERE verification_id = ?;', [verificationId]);
  },

  async findByToken(token) {
    return db.get(
      'SELECT * FROM EmailVerificationToken WHERE token = ? AND verified_at IS NULL ORDER BY created_at DESC LIMIT 1;',
      [token]
    );
  },

  async markTokenAsUsed(verificationId) {
    const sql = `
      UPDATE EmailVerificationToken 
      SET verified_at = CURRENT_TIMESTAMP 
      WHERE verification_id = ?;
    `;
    await db.run(sql, [verificationId]);
    return this.findById(verificationId);
  }
};

export default verificationRepository;
