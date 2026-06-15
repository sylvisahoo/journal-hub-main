import db from '../config/db.js';

export const analyticsRepository = {
  async getBasicStats(userId) {
    const sql = `
      SELECT COUNT(*) as totalEntries, SUM(word_count) as totalWords
      FROM JournalEntry
      WHERE user_id = ? AND deleted_at IS NULL;
    `;
    const row = await db.get(sql, [userId]);
    return {
      totalEntries: row ? row.totalEntries : 0,
      totalWords: row && row.totalWords ? row.totalWords : 0
    };
  },

  async getDistinctEntryDates(userId) {
    const sql = `
      SELECT DISTINCT strftime('%Y-%m-%d', entry_date) as entry_date
      FROM JournalEntry
      WHERE user_id = ? AND deleted_at IS NULL
      ORDER BY entry_date DESC;
    `;
    const rows = await db.all(sql, [userId]);
    return rows.map(r => r.entry_date).filter(Boolean);
  },

  async getMonthlyActivity(userId) {
    const sql = `
      SELECT strftime('%Y-%m', entry_date) as month, COUNT(*) as count
      FROM JournalEntry
      WHERE user_id = ? AND deleted_at IS NULL
      GROUP BY month
      ORDER BY month ASC;
    `;
    const rows = await db.all(sql, [userId]);
    return rows.map(r => ({
      month: r.month,
      count: r.count
    }));
  },

  async getHeatmapData(userId) {
    const sql = `
      SELECT strftime('%Y-%m-%d', entry_date) as date, COUNT(*) as count
      FROM JournalEntry
      WHERE user_id = ? AND deleted_at IS NULL
      GROUP BY date
      ORDER BY date ASC;
    `;
    const rows = await db.all(sql, [userId]);
    return rows.map(r => ({
      date: r.date,
      count: r.count
    }));
  }
};

export default analyticsRepository;
