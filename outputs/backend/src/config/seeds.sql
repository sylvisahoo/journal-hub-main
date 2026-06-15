-- Seed Data for Journal Hub Database

-- Clean up existing data (to avoid duplication when running seeds)
DELETE FROM AuditLog;
DELETE FROM Draft;
DELETE FROM Notification;
DELETE FROM ExportFile;
DELETE FROM ExportRequest;
DELETE FROM AnalyticsSnapshot;
DELETE FROM JournalShare;
DELETE FROM JournalTag;
DELETE FROM JournalEntryVersion;
DELETE FROM JournalEntry;
DELETE FROM Tag;
DELETE FROM Category;
DELETE FROM EmailVerificationToken;
DELETE FROM PasswordResetToken;
DELETE FROM UserSession;
DELETE FROM User;

-- 1. Users (password is 'Password123!')
INSERT INTO User (user_id, full_name, email, password_hash, account_status, created_at, updated_at, last_login_at)
VALUES 
('user-1', 'Verified User', 'verified@example.com', '$2b$10$tM7wJt0Wp.f/dJb/gP0hbeH3gM38zJ7jG2s8Qk9/wWpE0S02v/G1a', 'Verified', '2026-06-01 10:00:00', '2026-06-10 12:00:00', '2026-06-10 10:00:00'),
('user-2', 'Pending User', 'pending@example.com', '$2b$10$tM7wJt0Wp.f/dJb/gP0hbeH3gM38zJ7jG2s8Qk9/wWpE0S02v/G1a', 'Pending', '2026-06-09 11:00:00', '2026-06-09 11:00:00', NULL),
('user-3', 'Disabled User', 'disabled@example.com', '$2b$10$tM7wJt0Wp.f/dJb/gP0hbeH3gM38zJ7jG2s8Qk9/wWpE0S02v/G1a', 'Disabled', '2026-06-05 09:00:00', '2026-06-08 14:00:00', '2026-06-06 09:30:00');

-- 2. UserSession
INSERT INTO UserSession (session_id, user_id, access_token, refresh_token, expires_at, created_at, is_active)
VALUES
('session-1', 'user-1', 'access-token-12345', 'refresh-token-12345', '2026-06-17 10:00:00', '2026-06-10 10:00:00', 1);

-- 3. PasswordResetToken
INSERT INTO PasswordResetToken (reset_id, user_id, token, expires_at, used_at, created_at)
VALUES
('reset-1', 'user-1', 'reset-token-54321', '2026-06-10 11:00:00', '2026-06-10 10:30:00', '2026-06-10 10:00:00');

-- 4. EmailVerificationToken
INSERT INTO EmailVerificationToken (verification_id, user_id, token, expires_at, verified_at, created_at)
VALUES
('verification-1', 'user-2', 'verification-token-98765', '2026-06-12 11:00:00', NULL, '2026-06-09 11:00:00');

-- 5. Category
INSERT INTO Category (category_id, user_id, category_name, created_at)
VALUES
('category-1', 'user-1', 'Personal', '2026-06-01 10:05:00'),
('category-2', 'user-1', 'Work', '2026-06-01 10:05:00');

-- 6. Tag
INSERT INTO Tag (tag_id, user_id, tag_name, created_at)
VALUES
('tag-1', 'user-1', 'grateful', '2026-06-01 10:10:00'),
('tag-2', 'user-1', 'idea', '2026-06-01 10:10:00'),
('tag-3', 'user-1', 'meeting', '2026-06-01 10:10:00');

-- 7. JournalEntry
INSERT INTO JournalEntry (journal_id, user_id, category_id, title, content, entry_date, word_count, is_private, version_number, created_at, updated_at, deleted_at)
VALUES
('journal-1', 'user-1', 'category-1', 'My First Journal Entry', 'Today was a great day! I am grateful for everything.', '2026-06-10', 10, 1, 1, '2026-06-10 12:00:00', '2026-06-10 12:00:00', NULL),
('journal-2', 'user-1', 'category-2', 'Work brainstorm session', 'Brainstorming ideas for the next big project release.', '2026-06-09', 8, 0, 1, '2026-06-09 14:00:00', '2026-06-09 14:00:00', NULL);

-- 8. JournalEntryVersion
INSERT INTO JournalEntryVersion (version_id, journal_id, version_number, title, content, modified_at, modified_by)
VALUES
('version-1', 'journal-1', 1, 'My First Journal Entry', 'Today was a great day! I am grateful for everything.', '2026-06-10 12:00:00', 'user-1');

-- 9. JournalTag
INSERT INTO JournalTag (journal_tag_id, journal_id, tag_id)
VALUES
('journaltag-1', 'journal-1', 'tag-1'),
('journaltag-2', 'journal-2', 'tag-2'),
('journaltag-3', 'journal-2', 'tag-3');

-- 10. JournalShare
INSERT INTO JournalShare (share_id, journal_id, share_token, is_active, created_at, revoked_at)
VALUES
('share-1', 'journal-2', 'secure-public-token-123456', 1, '2026-06-10 13:00:00', NULL);

-- 11. AnalyticsSnapshot
INSERT INTO AnalyticsSnapshot (snapshot_id, user_id, total_entries, total_words, current_streak, monthly_entries, snapshot_date)
VALUES
('analytics-1', 'user-1', 2, 18, 2, 2, '2026-06-10');

-- 12. Notification
INSERT INTO Notification (notification_id, user_id, title, message, is_read, created_at)
VALUES
('notification-1', 'user-1', 'Welcome!', 'Welcome to Journal Hub. Start writing!', 0, '2026-06-01 10:00:00');

-- 13. Draft
INSERT INTO Draft (draft_id, user_id, journal_id, title, content, device_identifier, sync_status, saved_at)
VALUES
('draft-1', 'user-1', NULL, 'Work draft', 'Writing down preliminary ideas...', 'desktop-chrome', 'Pending', '2026-06-10 17:00:00');

-- 14. AuditLog
INSERT INTO AuditLog (audit_id, user_id, entity_type, entity_id, action_type, action_timestamp, ip_address, metadata)
VALUES
('audit-1', 'user-1', 'User', 'user-1', 'Register', '2026-06-01 10:00:00', '127.0.0.1', '{"method": "manual"}');
