import db from '../config/db.js';

export const tagRepository = {
  _mapRow(row) {
    if (!row) return null;
    return {
      tagId: row.tag_id,
      userId: row.user_id,
      tagName: row.tag_name,
      createdAt: row.created_at
    };
  },

  async findById(tagId) {
    const row = await db.get('SELECT * FROM Tag WHERE tag_id = ?;', [tagId]);
    return this._mapRow(row);
  },

  async findByUser(userId) {
    const rows = await db.all('SELECT * FROM Tag WHERE user_id = ? ORDER BY tag_name ASC;', [userId]);
    return rows.map((r) => this._mapRow(r));
  },

  async findByNameAndUser(tagName, userId) {
    const row = await db.get('SELECT * FROM Tag WHERE LOWER(tag_name) = ? AND user_id = ?;', [
      tagName.toLowerCase().trim(),
      userId
    ]);
    return this._mapRow(row);
  },

  async create({ tagId, userId, tagName }) {
    const sql = `
      INSERT INTO Tag (tag_id, user_id, tag_name, created_at)
      VALUES (?, ?, ?, CURRENT_TIMESTAMP);
    `;
    await db.run(sql, [tagId, userId, tagName.trim()]);
    return this.findById(tagId);
  }
};

export default tagRepository;
