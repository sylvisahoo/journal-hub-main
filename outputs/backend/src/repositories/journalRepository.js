import { v4 as uuidv4 } from 'uuid';
import db from '../config/db.js';

export const journalRepository = {
  // Helper to map DB row to API response model
  _mapRow(row, tagIds = []) {
    if (!row) return null;
    return {
      journalId: row.journal_id,
      userId: row.user_id,
      categoryId: row.category_id,
      title: row.title,
      content: row.content,
      entryDate: row.entry_date,
      wordCount: row.word_count,
      isPrivate: row.is_private === 1 || row.is_private === true || row.is_private === '1',
      versionNumber: row.version_number,
      createdAt: row.created_at,
      updatedAt: row.updated_at,
      deletedAt: row.deleted_at,
      tags: tagIds
    };
  },

  async findById(journalId) {
    const row = await db.get('SELECT * FROM JournalEntry WHERE journal_id = ?;', [journalId]);
    if (!row) return null;

    const tags = await db.all('SELECT tag_id FROM JournalTag WHERE journal_id = ?;', [journalId]);
    const tagIds = tags.map((t) => t.tag_id);
    return this._mapRow(row, tagIds);
  },

  async findByUser(userId, filters = {}) {
    const { startDate, endDate, tagId, categoryId, keyword, page = 1, limit = 100 } = filters;
    let sql = 'SELECT * FROM JournalEntry WHERE user_id = ? AND deleted_at IS NULL';
    const params = [userId];

    if (startDate) {
      sql += ' AND entry_date >= ?';
      params.push(startDate);
    }
    if (endDate) {
      sql += ' AND entry_date <= ?';
      params.push(endDate);
    }
    if (categoryId) {
      sql += ' AND category_id = ?';
      params.push(categoryId);
    }
    if (keyword) {
      sql += ' AND (title LIKE ? OR content LIKE ?)';
      const keywordPattern = `%${keyword}%`;
      params.push(keywordPattern, keywordPattern);
    }
    if (tagId) {
      sql += ' AND journal_id IN (SELECT journal_id FROM JournalTag WHERE tag_id = ?)';
      params.push(tagId);
    }

    // Default sorting by entry_date descending
    sql += ' ORDER BY entry_date DESC, created_at DESC';

    // Pagination
    const offset = (page - 1) * limit;
    sql += ' LIMIT ? OFFSET ?';
    params.push(limit, offset);

    const rows = await db.all(sql, params);

    // Fetch tags for all retrieved rows
    const entries = [];
    for (const row of rows) {
      const tags = await db.all('SELECT tag_id FROM JournalTag WHERE journal_id = ?;', [row.journal_id]);
      const tagIds = tags.map((t) => t.tag_id);
      entries.push(this._mapRow(row, tagIds));
    }

    return entries;
  },

  async createEntry(entry, tagIds = []) {
    const { journalId, userId, categoryId, title, content, entryDate, wordCount, isPrivate } = entry;
    
    await db.run('BEGIN TRANSACTION;');
    try {
      const sqlEntry = `
        INSERT INTO JournalEntry (
          journal_id, user_id, category_id, title, content, entry_date, 
          word_count, is_private, version_number, created_at, updated_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, 1, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);
      `;
      await db.run(sqlEntry, [
        journalId,
        userId,
        categoryId || null,
        title,
        content,
        entryDate,
        wordCount,
        isPrivate ? 1 : 0
      ]);

      for (const tagId of tagIds) {
        const journalTagId = `jt-${uuidv4()}`;
        await db.run(
          'INSERT INTO JournalTag (journal_tag_id, journal_id, tag_id) VALUES (?, ?, ?);',
          [journalTagId, journalId, tagId]
        );
      }

      await db.run('COMMIT;');
      return this.findById(journalId);
    } catch (err) {
      await db.run('ROLLBACK;');
      throw err;
    }
  },

  async updateEntry(entry, tagIds = []) {
    const { journalId, userId, categoryId, title, content, entryDate, wordCount, isPrivate } = entry;
    
    await db.run('BEGIN TRANSACTION;');
    try {
      // 1. Fetch current database record to copy into version history
      const current = await db.get('SELECT * FROM JournalEntry WHERE journal_id = ?;', [journalId]);
      if (!current) {
        throw new Error('ENTRY_NOT_FOUND');
      }

      // 2. Insert into JournalEntryVersion
      const versionId = `jv-${uuidv4()}`;
      const sqlVersion = `
        INSERT INTO JournalEntryVersion (version_id, journal_id, version_number, title, content, modified_at, modified_by)
        VALUES (?, ?, ?, ?, ?, ?, ?);
      `;
      await db.run(sqlVersion, [
        versionId,
        journalId,
        current.version_number,
        current.title,
        current.content,
        current.updated_at,
        userId
      ]);

      // 3. Update JournalEntry, incrementing version_number
      const newVersion = current.version_number + 1;
      const sqlUpdate = `
        UPDATE JournalEntry 
        SET category_id = ?, title = ?, content = ?, entry_date = ?, 
            word_count = ?, is_private = ?, version_number = ?, updated_at = CURRENT_TIMESTAMP
        WHERE journal_id = ?;
      `;
      await db.run(sqlUpdate, [
        categoryId || null,
        title,
        content,
        entryDate,
        wordCount,
        isPrivate ? 1 : 0,
        newVersion,
        journalId
      ]);

      // 4. Update tags
      await db.run('DELETE FROM JournalTag WHERE journal_id = ?;', [journalId]);
      for (const tagId of tagIds) {
        const journalTagId = `jt-${uuidv4()}`;
        await db.run(
          'INSERT INTO JournalTag (journal_tag_id, journal_id, tag_id) VALUES (?, ?, ?);',
          [journalTagId, journalId, tagId]
        );
      }

      await db.run('COMMIT;');
      return this.findById(journalId);
    } catch (err) {
      await db.run('ROLLBACK;');
      throw err;
    }
  },

  async softDeleteEntry(journalId) {
    await db.run('UPDATE JournalEntry SET deleted_at = CURRENT_TIMESTAMP WHERE journal_id = ?;', [
      journalId
    ]);
  },

  async hardDeleteEntry(journalId) {
    await db.run('DELETE FROM JournalEntry WHERE journal_id = ?;', [journalId]);
  },

  async getVersionHistory(journalId) {
    const rows = await db.all(
      'SELECT * FROM JournalEntryVersion WHERE journal_id = ? ORDER BY version_number DESC;',
      [journalId]
    );
    return rows.map((r) => ({
      versionId: r.version_id,
      journalId: r.journal_id,
      versionNumber: r.version_number,
      title: r.title,
      content: r.content,
      modifiedAt: r.modified_at,
      modifiedBy: r.modified_by
    }));
  },

  async findDatesByMonthAndYear(userId, month, year) {
    const monthStr = String(month).padStart(2, '0');
    const yearStr = String(year);
    const sql = `
      SELECT DISTINCT entry_date
      FROM JournalEntry
      WHERE user_id = ? AND deleted_at IS NULL
        AND strftime('%Y', entry_date) = ?
        AND strftime('%m', entry_date) = ?
      ORDER BY entry_date ASC;
    `;
    const rows = await db.all(sql, [userId, yearStr, monthStr]);
    return rows.map((row) => {
      const d = row.entry_date;
      return d.includes('T') ? d.split('T')[0] : d;
    });
  }
};

export default journalRepository;
