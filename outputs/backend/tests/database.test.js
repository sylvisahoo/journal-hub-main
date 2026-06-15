import db from '../src/config/db.js';
import { initDatabase } from '../src/config/initDb.js';

describe('Database Schema & Integrity Tests', () => {
  beforeAll(async () => {
    // Re-initialize database schema for testing (do not seed, we will write custom tests)
    await initDatabase(false);
  });

  afterAll(async () => {
    // Clean up connection
    await db.close();
  });

  test('All 16 tables should exist in the schema', async () => {
    const tables = [
      'User',
      'UserSession',
      'PasswordResetToken',
      'EmailVerificationToken',
      'Category',
      'Tag',
      'JournalEntry',
      'JournalEntryVersion',
      'JournalTag',
      'JournalShare',
      'AnalyticsSnapshot',
      'ExportRequest',
      'ExportFile',
      'Notification',
      'Draft',
      'AuditLog'
    ];

    for (const table of tables) {
      const row = await db.get("SELECT name FROM sqlite_master WHERE type='table' AND name=?;", [table]);
      expect(row).toBeDefined();
      expect(row.name).toBe(table);
    }
  });

  test('All indexes should exist in the schema', async () => {
    const indexes = [
      'idx_user_email',
      'idx_user_account_status',
      'idx_usersession_user_id',
      'idx_usersession_expires_at',
      'idx_journalentry_user_id',
      'idx_journalentry_entry_date',
      'idx_journalentry_updated_at',
      'idx_journalentry_deleted_at',
      'idx_journalentry_title',
      'idx_tag_tag_name',
      'idx_journaltag_journal_id',
      'idx_journaltag_tag_id',
      'idx_journalshare_share_token',
      'idx_journalshare_is_active',
      'idx_analytics_user_date',
      'idx_exportrequest_user_id',
      'idx_exportrequest_status',
      'idx_auditlog_user_id',
      'idx_auditlog_timestamp'
    ];

    for (const index of indexes) {
      const row = await db.get("SELECT name FROM sqlite_master WHERE type='index' AND name=?;", [index]);
      expect(row).toBeDefined();
      expect(row.name).toBe(index);
    }
  });

  describe('Constraints and Integrity Checks', () => {
    beforeEach(async () => {
      // Clear tables in reverse dependency order to ensure clean state
      const tables = [
        'AuditLog',
        'Draft',
        'Notification',
        'ExportFile',
        'ExportRequest',
        'AnalyticsSnapshot',
        'JournalShare',
        'JournalTag',
        'JournalEntryVersion',
        'JournalEntry',
        'Tag',
        'Category',
        'EmailVerificationToken',
        'PasswordResetToken',
        'UserSession',
        'User'
      ];
      for (const table of tables) {
        await db.run(`DELETE FROM ${table};`);
      }
    });

    test('User account_status CHECK constraint validation', async () => {
      // Valid insertion
      await expect(
        db.run(
          'INSERT INTO User (user_id, full_name, email, password_hash, account_status) VALUES (?, ?, ?, ?, ?);',
          ['u-test-1', 'Test User', 'test1@example.com', 'hash123', 'Verified']
        )
      ).resolves.toBeDefined();

      // Invalid insertion
      await expect(
        db.run(
          'INSERT INTO User (user_id, full_name, email, password_hash, account_status) VALUES (?, ?, ?, ?, ?);',
          ['u-test-2', 'Test User', 'test2@example.com', 'hash123', 'InvalidStatus']
        )
      ).rejects.toThrow();
    });

    test('User email UNIQUE constraint validation', async () => {
      await db.run(
        'INSERT INTO User (user_id, full_name, email, password_hash, account_status) VALUES (?, ?, ?, ?, ?);',
        ['u-test-1', 'User One', 'same@example.com', 'hash', 'Verified']
      );

      await expect(
        db.run(
          'INSERT INTO User (user_id, full_name, email, password_hash, account_status) VALUES (?, ?, ?, ?, ?);',
          ['u-test-2', 'User Two', 'same@example.com', 'hash', 'Verified']
        )
      ).rejects.toThrow();
    });

    test('Foreign Key Cascading Deletions validation', async () => {
      // Insert User
      await db.run(
        'INSERT INTO User (user_id, full_name, email, password_hash, account_status) VALUES (?, ?, ?, ?, ?);',
        ['u-test-1', 'Test User', 'test@example.com', 'hash', 'Verified']
      );

      // Insert UserSession
      await db.run(
        'INSERT INTO UserSession (session_id, user_id, access_token, refresh_token, expires_at) VALUES (?, ?, ?, ?, ?);',
        ['s-test-1', 'u-test-1', 'access-token', 'refresh-token', '2026-12-31 23:59:59']
      );

      // Verify Session exists
      const sessionBefore = await db.get("SELECT * FROM UserSession WHERE session_id = 's-test-1';");
      expect(sessionBefore).toBeDefined();

      // Delete User
      await db.run("DELETE FROM User WHERE user_id = 'u-test-1';");

      // Verify Session was deleted automatically via cascade delete
      const sessionAfter = await db.get("SELECT * FROM UserSession WHERE session_id = 's-test-1';");
      expect(sessionAfter).toBeUndefined();
    });

    test('Compound Unique Key constraint on Category and Tag per user validation', async () => {
      // Insert User
      await db.run(
        'INSERT INTO User (user_id, full_name, email, password_hash, account_status) VALUES (?, ?, ?, ?, ?);',
        ['u-test-1', 'Test User', 'test@example.com', 'hash', 'Verified']
      );

      // Category Valid Insertion
      await db.run(
        'INSERT INTO Category (category_id, user_id, category_name) VALUES (?, ?, ?);',
        ['c-test-1', 'u-test-1', 'Personal']
      );

      // Category Duplicate Insertion per user -> fail
      await expect(
        db.run(
          'INSERT INTO Category (category_id, user_id, category_name) VALUES (?, ?, ?);',
          ['c-test-2', 'u-test-1', 'Personal']
        )
      ).rejects.toThrow();

      // Tag Valid Insertion
      await db.run(
        'INSERT INTO Tag (tag_id, user_id, tag_name) VALUES (?, ?, ?);',
        ['t-test-1', 'u-test-1', 'grateful']
      );

      // Tag Duplicate Insertion per user -> fail
      await expect(
        db.run(
          'INSERT INTO Tag (tag_id, user_id, tag_name) VALUES (?, ?, ?);',
          ['t-test-2', 'u-test-1', 'grateful']
        )
      ).rejects.toThrow();
    });

    test('JournalEntry version_number CHECK constraint validation', async () => {
      // Insert User
      await db.run(
        'INSERT INTO User (user_id, full_name, email, password_hash, account_status) VALUES (?, ?, ?, ?, ?);',
        ['u-test-1', 'Test User', 'test@example.com', 'hash', 'Verified']
      );

      // Valid entry
      await expect(
        db.run(
          'INSERT INTO JournalEntry (journal_id, user_id, title, content, entry_date) VALUES (?, ?, ?, ?, ?);',
          ['j-test-1', 'u-test-1', 'Title', 'Content', '2026-06-10']
        )
      ).resolves.toBeDefined();

      // Negative version number -> CHECK constraint fails
      await expect(
        db.run(
          'INSERT INTO JournalEntry (journal_id, user_id, title, content, entry_date, version_number) VALUES (?, ?, ?, ?, ?, ?);',
          ['j-test-2', 'u-test-1', 'Title', 'Content', '2026-06-10', -1]
        )
      ).rejects.toThrow();
    });
  });
});
