# Implementation Plan - Phase 2: Database Design

Design, initialize, and verify the SQLite database schema, constraints, indexes, and seed data for **Journal Hub** under [outputs/backend](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/backend).

## User Review Required

> [!IMPORTANT]
> The database implementation enforces standard SQLite relational integrity. 
> To guarantee foreign key cascade operations work dynamically, the connection hook automatically executes `PRAGMA foreign_keys = ON;`.
> 
> The `Notification` table columns have been fully designed as:
> - `notification_id` Text (Primary Key)
> - `user_id` Text (Foreign Key to User, Cascade Delete, Not Null)
> - `title` Text (Not Null)
> - `message` Text (Not Null)
> - `is_read` Boolean (Not Null Default 0)
> - `created_at` DateTime (Not Null Default CURRENT_TIMESTAMP)

---

## Proposed Changes

### [Database Setup]

We will create and update files under [outputs/backend](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/backend).

#### [NEW] [schema.sql](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/backend/src/config/schema.sql)
SQL script defining the DDL schema for all 16 tables:
1. `User` (account_status validation check constraint)
2. `UserSession` (references User)
3. `PasswordResetToken` (references User)
4. `EmailVerificationToken` (references User)
5. `Category` (unique category_name per user, references User)
6. `Tag` (unique tag_name per user, references User)
7. `JournalEntry` (version_number validation check, references User/Category)
8. `JournalEntryVersion` (references JournalEntry/User)
9. `JournalTag` (junction unique composite key, references JournalEntry/Tag)
10. `JournalShare` (unique share_token, references JournalEntry)
11. `AnalyticsSnapshot` (references User)
12. `ExportRequest` (export_format/export_status validation checks, references User)
13. `ExportFile` (references ExportRequest)
14. `Notification` (references User)
15. `Draft` (sync_status validation check, references User/JournalEntry)
16. `AuditLog` (references User)

Also includes all performance indexes defined in the Index Strategy.

#### [NEW] [seeds.sql](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/backend/src/config/seeds.sql)
SQL insert script with mock development data (pre-configured verified users, categories, tags, journals, and sessions) for local testing and seeding.

#### [NEW] [initDb.js](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/backend/src/config/initDb.js)
Database migration controller script:
- Reads and parses the DDL schema in `schema.sql`
- Runs all creation commands serially on SQLite connection
- Runs `seeds.sql` if a `--seed` command-line flag is passed

#### [MODIFY] [db.js](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/backend/src/config/db.js)
Integrate auto-migration at start-up:
- Read check whether schema tables exist. If database is completely empty (no tables), automatically execute the `initDb` initialization script.

#### [NEW] [database.test.js](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/backend/tests/database.test.js)
A comprehensive integration test suite utilizing Jest to verify:
- Creation and validation of all 16 tables
- Relational integrity constraints (foreign key cascade deletions work, unique compound constraints prevent duplicate tags/categories per user)
- Validation constraints (invalid status checks throw SQL errors)
- Index verification (indexes are created on target tables)

---

## Verification Plan

### Automated Tests
- Run `npm test` to run all test suites including the new database integrity tests.
- Verify cascading deletion behavior automatically via tests.
- Verify Joi validations, unique tags, and check constraints under test cases.

### Manual Verification
- Run database seeding explicitly: `node src/config/initDb.js --seed`.
- Inspect generated `outputs/backend/data/journal.db` file using `sqlite3` CLI tool to verify schemas, rows, and constraints are in place.
