import db from '../config/db.js';

export const userRepository = {
  async findByEmail(email) {
    return db.get('SELECT * FROM User WHERE email = ?;', [email.toLowerCase()]);
  },

  async findById(userId) {
    return db.get('SELECT * FROM User WHERE user_id = ?;', [userId]);
  },

  async createUser(user) {
    const { userId, fullName, email, passwordHash, accountStatus = 'Pending' } = user;
    const sql = `
      INSERT INTO User (user_id, full_name, email, password_hash, account_status, created_at, updated_at)
      VALUES (?, ?, ?, ?, ?, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);
    `;
    await db.run(sql, [userId, fullName, email.toLowerCase(), passwordHash, accountStatus]);
    return this.findById(userId);
  },

  async updateUserStatus(userId, status) {
    const sql = `
      UPDATE User 
      SET account_status = ?, updated_at = CURRENT_TIMESTAMP 
      WHERE user_id = ?;
    `;
    await db.run(sql, [status, userId]);
    return this.findById(userId);
  },

  async updatePassword(userId, passwordHash) {
    const sql = `
      UPDATE User 
      SET password_hash = ?, updated_at = CURRENT_TIMESTAMP 
      WHERE user_id = ?;
    `;
    await db.run(sql, [passwordHash, userId]);
    return this.findById(userId);
  },

  async updateLastLogin(userId) {
    const sql = `
      UPDATE User 
      SET last_login_at = CURRENT_TIMESTAMP 
      WHERE user_id = ?;
    `;
    await db.run(sql, [userId]);
    return this.findById(userId);
  }
};

export default userRepository;
