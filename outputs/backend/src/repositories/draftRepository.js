import db from '../config/db.js';

export const draftRepository = {
  async findById(draftId) {
    return db.get('SELECT * FROM Draft WHERE draft_id = ?;', [draftId]);
  },

  async findLatestDraftByJournalId(userId, journalId) {
    return db.get('SELECT * FROM Draft WHERE user_id = ? AND journal_id = ? ORDER BY saved_at DESC LIMIT 1;', [userId, journalId]);
  },

  async upsertDraft(draft) {
    const { draftId, userId, journalId = null, title = '', content = '', deviceIdentifier = 'mobile', syncStatus = 'Synced' } = draft;
    const sql = `
      INSERT OR REPLACE INTO Draft (draft_id, user_id, journal_id, title, content, device_identifier, sync_status, saved_at)
      VALUES (?, ?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP);
    `;
    await db.run(sql, [draftId, userId, journalId, title, content, deviceIdentifier, syncStatus]);
    return this.findById(draftId);
  },

  async deleteDraft(draftId) {
    await db.run('DELETE FROM Draft WHERE draft_id = ?;', [draftId]);
  }
};

export default draftRepository;
