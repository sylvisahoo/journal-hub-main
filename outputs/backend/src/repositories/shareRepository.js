import db from '../config/db.js';

export const shareRepository = {
  _mapRow(row) {
    if (!row) return null;
    return {
      shareId: row.share_id,
      journalId: row.journal_id,
      shareToken: row.share_token,
      isActive: row.is_active === 1 || row.is_active === true || row.is_active === '1',
      createdAt: row.created_at,
      revokedAt: row.revoked_at
    };
  },

  async createShare(shareId, journalId, shareToken) {
    const sql = `
      INSERT INTO JournalShare (share_id, journal_id, share_token, is_active, created_at)
      VALUES (?, ?, ?, 1, CURRENT_TIMESTAMP);
    `;
    await db.run(sql, [shareId, journalId, shareToken]);
    return this.findById(shareId);
  },

  async findById(shareId) {
    const row = await db.get('SELECT * FROM JournalShare WHERE share_id = ?;', [shareId]);
    return this._mapRow(row);
  },

  async findActiveByJournalId(journalId) {
    const row = await db.get('SELECT * FROM JournalShare WHERE journal_id = ? AND is_active = 1;', [journalId]);
    return this._mapRow(row);
  },

  async findByToken(shareToken) {
    const row = await db.get('SELECT * FROM JournalShare WHERE share_token = ?;', [shareToken]);
    return this._mapRow(row);
  },

  async deactivateSharesByJournalId(journalId) {
    const sql = `
      UPDATE JournalShare
      SET is_active = 0, revoked_at = CURRENT_TIMESTAMP
      WHERE journal_id = ? AND is_active = 1;
    `;
    await db.run(sql, [journalId]);
  }
};

export default shareRepository;
