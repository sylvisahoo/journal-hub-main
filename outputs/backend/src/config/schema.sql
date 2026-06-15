-- DDL Schema for Journal Hub SQLite Database

-- Enable PRAGMA statement is handled programmatically in connection, 
-- but added here as documentation reference.
PRAGMA foreign_keys = ON;

-- 1. User
CREATE TABLE IF NOT EXISTS User (
    user_id TEXT PRIMARY KEY,
    full_name TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    account_status TEXT NOT NULL CHECK(account_status IN ('Pending', 'Verified', 'Disabled')),
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    last_login_at DATETIME
);

-- 2. UserSession
CREATE TABLE IF NOT EXISTS UserSession (
    session_id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    access_token TEXT NOT NULL,
    refresh_token TEXT NOT NULL,
    expires_at DATETIME NOT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN NOT NULL DEFAULT 1,
    FOREIGN KEY(user_id) REFERENCES User(user_id) ON DELETE CASCADE
);

-- 3. PasswordResetToken
CREATE TABLE IF NOT EXISTS PasswordResetToken (
    reset_id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    token TEXT NOT NULL,
    expires_at DATETIME NOT NULL,
    used_at DATETIME,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY(user_id) REFERENCES User(user_id) ON DELETE CASCADE
);

-- 4. EmailVerificationToken
CREATE TABLE IF NOT EXISTS EmailVerificationToken (
    verification_id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    token TEXT NOT NULL,
    expires_at DATETIME NOT NULL,
    verified_at DATETIME,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY(user_id) REFERENCES User(user_id) ON DELETE CASCADE
);

-- 5. Category
CREATE TABLE IF NOT EXISTS Category (
    category_id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    category_name TEXT NOT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY(user_id) REFERENCES User(user_id) ON DELETE CASCADE,
    UNIQUE(user_id, category_name)
);

-- 6. Tag
CREATE TABLE IF NOT EXISTS Tag (
    tag_id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    tag_name TEXT NOT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY(user_id) REFERENCES User(user_id) ON DELETE CASCADE,
    UNIQUE(user_id, tag_name)
);

-- 7. JournalEntry
CREATE TABLE IF NOT EXISTS JournalEntry (
    journal_id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    category_id TEXT,
    title TEXT NOT NULL,
    content TEXT NOT NULL,
    entry_date DATE NOT NULL,
    word_count INTEGER NOT NULL DEFAULT 0,
    is_private BOOLEAN NOT NULL DEFAULT 1,
    version_number INTEGER NOT NULL DEFAULT 1 CHECK(version_number >= 0),
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at DATETIME,
    FOREIGN KEY(user_id) REFERENCES User(user_id) ON DELETE CASCADE,
    FOREIGN KEY(category_id) REFERENCES Category(category_id) ON DELETE SET NULL
);

-- 8. JournalEntryVersion
CREATE TABLE IF NOT EXISTS JournalEntryVersion (
    version_id TEXT PRIMARY KEY,
    journal_id TEXT NOT NULL,
    version_number INTEGER NOT NULL,
    title TEXT NOT NULL,
    content TEXT NOT NULL,
    modified_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    modified_by TEXT NOT NULL,
    FOREIGN KEY(journal_id) REFERENCES JournalEntry(journal_id) ON DELETE CASCADE,
    FOREIGN KEY(modified_by) REFERENCES User(user_id) ON DELETE CASCADE
);

-- 9. JournalTag
CREATE TABLE IF NOT EXISTS JournalTag (
    journal_tag_id TEXT PRIMARY KEY,
    journal_id TEXT NOT NULL,
    tag_id TEXT NOT NULL,
    FOREIGN KEY(journal_id) REFERENCES JournalEntry(journal_id) ON DELETE CASCADE,
    FOREIGN KEY(tag_id) REFERENCES Tag(tag_id) ON DELETE CASCADE,
    UNIQUE(journal_id, tag_id)
);

-- 10. JournalShare
CREATE TABLE IF NOT EXISTS JournalShare (
    share_id TEXT PRIMARY KEY,
    journal_id TEXT NOT NULL,
    share_token TEXT UNIQUE NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT 1,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    revoked_at DATETIME,
    FOREIGN KEY(journal_id) REFERENCES JournalEntry(journal_id) ON DELETE CASCADE
);

-- 11. AnalyticsSnapshot
CREATE TABLE IF NOT EXISTS AnalyticsSnapshot (
    snapshot_id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    total_entries INTEGER NOT NULL DEFAULT 0,
    total_words INTEGER NOT NULL DEFAULT 0,
    current_streak INTEGER NOT NULL DEFAULT 0,
    monthly_entries INTEGER NOT NULL DEFAULT 0,
    snapshot_date DATE NOT NULL,
    FOREIGN KEY(user_id) REFERENCES User(user_id) ON DELETE CASCADE
);

-- 12. ExportRequest
CREATE TABLE IF NOT EXISTS ExportRequest (
    export_id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    export_format TEXT NOT NULL CHECK(export_format IN ('PDF', 'DOCX', 'JSON')),
    export_status TEXT NOT NULL CHECK(export_status IN ('Pending', 'Processing', 'Completed', 'Failed')),
    requested_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    completed_at DATETIME,
    FOREIGN KEY(user_id) REFERENCES User(user_id) ON DELETE CASCADE
);

-- 13. ExportFile
CREATE TABLE IF NOT EXISTS ExportFile (
    file_id TEXT PRIMARY KEY,
    export_id TEXT NOT NULL,
    file_name TEXT NOT NULL,
    download_url TEXT NOT NULL,
    expires_at DATETIME NOT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY(export_id) REFERENCES ExportRequest(export_id) ON DELETE CASCADE
);

-- 14. Notification
CREATE TABLE IF NOT EXISTS Notification (
    notification_id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    is_read BOOLEAN NOT NULL DEFAULT 0,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY(user_id) REFERENCES User(user_id) ON DELETE CASCADE
);

-- 15. Draft
CREATE TABLE IF NOT EXISTS Draft (
    draft_id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    journal_id TEXT,
    title TEXT,
    content TEXT,
    device_identifier TEXT,
    sync_status TEXT NOT NULL CHECK(sync_status IN ('Pending', 'Synced')),
    saved_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY(user_id) REFERENCES User(user_id) ON DELETE CASCADE,
    FOREIGN KEY(journal_id) REFERENCES JournalEntry(journal_id) ON DELETE SET NULL
);

-- 16. AuditLog
CREATE TABLE IF NOT EXISTS AuditLog (
    audit_id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    entity_type TEXT NOT NULL,
    entity_id TEXT,
    action_type TEXT NOT NULL,
    action_timestamp DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ip_address TEXT,
    metadata TEXT,
    FOREIGN KEY(user_id) REFERENCES User(user_id) ON DELETE CASCADE
);

-- Indexes

-- Authentication Indexes
CREATE INDEX IF NOT EXISTS idx_user_email ON User(email);
CREATE INDEX IF NOT EXISTS idx_user_account_status ON User(account_status);
CREATE INDEX IF NOT EXISTS idx_usersession_user_id ON UserSession(user_id);
CREATE INDEX IF NOT EXISTS idx_usersession_expires_at ON UserSession(expires_at);

-- Journal Operations Indexes
CREATE INDEX IF NOT EXISTS idx_journalentry_user_id ON JournalEntry(user_id);
CREATE INDEX IF NOT EXISTS idx_journalentry_entry_date ON JournalEntry(entry_date);
CREATE INDEX IF NOT EXISTS idx_journalentry_updated_at ON JournalEntry(updated_at);
CREATE INDEX IF NOT EXISTS idx_journalentry_deleted_at ON JournalEntry(deleted_at);
CREATE INDEX IF NOT EXISTS idx_journalentry_title ON JournalEntry(title);

-- Search & Filtering Indexes
CREATE INDEX IF NOT EXISTS idx_tag_tag_name ON Tag(tag_name);
CREATE INDEX IF NOT EXISTS idx_journaltag_journal_id ON JournalTag(journal_id);
CREATE INDEX IF NOT EXISTS idx_journaltag_tag_id ON JournalTag(tag_id);

-- Sharing Indexes
CREATE INDEX IF NOT EXISTS idx_journalshare_share_token ON JournalShare(share_token);
CREATE INDEX IF NOT EXISTS idx_journalshare_is_active ON JournalShare(is_active);

-- Analytics Indexes
CREATE INDEX IF NOT EXISTS idx_analytics_user_date ON AnalyticsSnapshot(user_id, snapshot_date);

-- Exports Indexes
CREATE INDEX IF NOT EXISTS idx_exportrequest_user_id ON ExportRequest(user_id);
CREATE INDEX IF NOT EXISTS idx_exportrequest_status ON ExportRequest(export_status);

-- Auditing Indexes
CREATE INDEX IF NOT EXISTS idx_auditlog_user_id ON AuditLog(user_id);
CREATE INDEX IF NOT EXISTS idx_auditlog_timestamp ON AuditLog(action_timestamp);
