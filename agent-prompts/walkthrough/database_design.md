# Walkthrough - Database Design (Phase 2)

Successfully completed **Phase 2: Database Design** for the **Journal Hub** application under [outputs/backend](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/backend).

## Changes Made

### 1. Database Schema DDL
Created [schema.sql](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/backend/src/config/schema.sql) containing DDL statements for all 16 tables defined in `database-design.md`:
- `User`, `UserSession`, `PasswordResetToken`, `EmailVerificationToken`, `Category`, `Tag`, `JournalEntry`, `JournalEntryVersion`, `JournalTag`, `JournalShare`, `AnalyticsSnapshot`, `ExportRequest`, `ExportFile`, `Notification`, `Draft`, and `AuditLog`.
- Applied check constraints (`account_status`, `export_format`, `export_status`, `sync_status`, `version_number >= 0`).
- Enforced foreign key references with `ON DELETE CASCADE` or `ON DELETE SET NULL` constraints.
- Created all 19 indices matching the index strategy in `database-design.md`.

### 2. Database Seeding DDL
Created [seeds.sql](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/backend/src/config/seeds.sql) containing SQL commands to clean existing data and seed mock records (verified, pending, and disabled users, categories, tags, journals, shares, analytics, notifications, drafts, and audit logs) for development.

### 3. Database Initialization Engine
Created [initDb.js](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/backend/src/config/initDb.js) which reads `schema.sql` and `seeds.sql` and executes them via `db.exec()`. It supports a `--seed` or `-s` command-line flag for manual seeding.

### 4. Automatic Startup Migrations
Modified [server.js](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/backend/src/server.js) to check for table existence on startup. If no tables exist, it automatically imports `initDb.js` and runs the schema initialization dynamically. Seeding is applied automatically if the environment is `development`.

### 5. Automated Integrity Tests
Created [database.test.js](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/backend/tests/database.test.js) containing integration test suites validating schema correctness:
- Verifies all 16 tables and 19 indexes exist in the schema.
- Validates constraints (checks correct input range, uniqueness of email/tags/categories per user, positive version numbers).
- Validates Cascading Deletions: deleting a user deletes related sessions and journals automatically.

---

## Verification Results

### Automated Integration Tests
Ran `npm test` verifying all test suites. All 9 tests passed:
```text
info: Initializing database schema...
info: Connected to SQLite database at: /Users/neo/Desktop/Vibe Coding Training/vibe_projects/journal-hub/outputs/backend/data/journal.db
info: SQLite Foreign Key constraints enabled.
info: Database schema initialized successfully.
PASS tests/database.test.js
  Database Schema & Integrity Tests
    ✓ All 16 tables should exist in the schema (13 ms)
    ✓ All indexes should exist in the schema (4 ms)
    Constraints and Integrity Checks
      ✓ User account_status CHECK constraint validation (6 ms)
      ✓ User email UNIQUE constraint validation (4 ms)
      ✓ Foreign Key Cascading Deletions validation (6 ms)
      ✓ Compound Unique Key constraint on Category and Tag per user validation (6 ms)
      ✓ JournalEntry version_number CHECK constraint validation (6 ms)

info: Connected to SQLite database at: /Users/neo/Desktop/Vibe Coding Training/vibe_projects/journal-hub/outputs/backend/data/journal.db
info: GET /api/v1/health 200 100 - 4.587 ms
info: SQLite Foreign Key constraints enabled.
info: GET /api/v1/undefined-route-check 404 156 - 1.855 ms
PASS tests/sanity.test.js
  Sanity & Configuration Tests
    GET /api/v1/health
      ✓ should return 200 OK with the health check details (33 ms)
    GET /api/v1/undefined-route-check
      ✓ should return 404 NOT_FOUND and match the standard error response contract (7 ms)

Test Suites: 2 passed, 2 total
Tests:       9 passed, 9 total
Snapshots:   0 total
Time:        0.598 s
Ran all test suites.
```

### Manual Seeding Verification
1. Executed `node src/config/initDb.js --seed`:
   ```text
   info: Initializing database schema...
   info: Connected to SQLite database at: /Users/neo/Desktop/Vibe Coding Training/vibe_projects/journal-hub/outputs/backend/data/journal.db
   info: SQLite Foreign Key constraints enabled.
   info: Database schema initialized successfully.
   info: Seeding mock database records...
   info: Database seeding completed successfully.
   info: Database initialization script finished successfully.
   ```
2. Queried database tables manually to confirm mock data:
   ```bash
   sqlite3 data/journal.db "SELECT * FROM User;"
   ```
   **Output:**
   ```text
   user-1|Verified User|verified@example.com|$2b$10$tM7wJt0Wp.f/dJb/gP0hbeH3gM38zJ7jG2s8Qk9/wWpE0S02v/G1a|Verified|2026-06-01 10:00:00|2026-06-10 12:00:00|2026-06-10 10:00:00
   user-2|Pending User|pending@example.com|$2b$10$tM7wJt0Wp.f/dJb/gP0hbeH3gM38zJ7jG2s8Qk9/wWpE0S02v/G1a|Pending|2026-06-09 11:00:00|2026-06-09 11:00:00|
   user-3|Disabled User|disabled@example.com|$2b$10$tM7wJt0Wp.f/dJb/gP0hbeH3gM38zJ7jG2s8Qk9/wWpE0S02v/G1a|Disabled|2026-06-05 09:00:00|2026-06-08 14:00:00|2026-06-06 09:30:00
   ```
