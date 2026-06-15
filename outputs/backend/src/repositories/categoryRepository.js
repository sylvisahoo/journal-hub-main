import db from '../config/db.js';

export const categoryRepository = {
  _mapRow(row) {
    if (!row) return null;
    return {
      categoryId: row.category_id,
      userId: row.user_id,
      categoryName: row.category_name,
      createdAt: row.created_at
    };
  },

  async findById(categoryId) {
    const row = await db.get('SELECT * FROM Category WHERE category_id = ?;', [categoryId]);
    return this._mapRow(row);
  },

  async findByUser(userId) {
    const rows = await db.all('SELECT * FROM Category WHERE user_id = ? ORDER BY category_name ASC;', [userId]);
    return rows.map((r) => this._mapRow(r));
  },

  async findByNameAndUser(categoryName, userId) {
    const row = await db.get('SELECT * FROM Category WHERE LOWER(category_name) = ? AND user_id = ?;', [
      categoryName.toLowerCase(),
      userId
    ]);
    return this._mapRow(row);
  },

  async create({ categoryId, userId, categoryName }) {
    const sql = `
      INSERT INTO Category (category_id, user_id, category_name, created_at)
      VALUES (?, ?, ?, CURRENT_TIMESTAMP);
    `;
    await db.run(sql, [categoryId, userId, categoryName]);
    return this.findById(categoryId);
  }
};

export default categoryRepository;
