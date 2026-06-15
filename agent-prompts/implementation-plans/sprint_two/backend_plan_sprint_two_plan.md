# Implementation Plan - Sprint 2 Backend Modules (Journal Entry Creation, Editing, Deletion)

We will implement Modules 3, 4, and 5 in the Node.js Express backend, providing full CRUD support for journal entries, category management, tag management, version history recording, optimistic conflict detection, soft deletes, and security checks.

## Proposed Changes

### Component: Database & Repositories

We will create three new repositories to handle all database queries.

#### [NEW] [categoryRepository.js](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/backend/src/repositories/categoryRepository.js)
Provide CRUD operations on the `Category` table:
- `create({ categoryId, userId, categoryName })`
- `findById(categoryId)`
- `findByUser(userId)`
- `findByNameAndUser(categoryName, userId)`

#### [NEW] [tagRepository.js](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/backend/src/repositories/tagRepository.js)
Provide CRUD operations on the `Tag` table:
- `create({ tagId, userId, tagName })`
- `findById(tagId)`
- `findByUser(userId)`
- `findByNameAndUser(tagName, userId)`

#### [NEW] [journalRepository.js](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/backend/src/repositories/journalRepository.js)
Provide CRUD and versioning operations on the `JournalEntry`, `JournalEntryVersion`, and `JournalTag` tables:
- `createEntry(entry, tagIds)`: Inserts a journal entry and inserts corresponding `JournalTag` associations in a transaction.
- `findById(journalId)`: Fetches a single journal entry by ID, including its associated `tags` (as a list of tag objects or IDs) and `category_name`.
- `findByUser(userId, filters)`: Lists active entries (`deleted_at IS NULL`) for a user, applying filters (`startDate`, `endDate`, `tagId`, `categoryId`, `keyword`).
- `updateEntry(entry, tagIds)`: Performs updates, increments version number, updates `JournalTag` associations, and records the historical version in `JournalEntryVersion` in a transaction.
- `softDeleteEntry(journalId)`: Updates `deleted_at = CURRENT_TIMESTAMP` for the entry.
- `hardDeleteEntry(journalId)`: Deletes the entry and cascaded relations from the database.
- `getVersionHistory(journalId)`: Retrieves all historical versions of an entry from `JournalEntryVersion`.

---

### Component: Services

We will create business logic layers to handle validations, word counts, and exception handling.

#### [NEW] [categoryService.js](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/backend/src/services/categoryService.js)
- `createCategory(userId, categoryName)`: Validates name uniqueness per user, throws `DUPLICATE_CATEGORY` (409) if duplicate.
- `getCategories(userId)`: Returns all categories owned by the user.

#### [NEW] [tagService.js](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/backend/src/services/tagService.js)
- `createTag(userId, tagName)`: Validates tag uniqueness per user, throws `DUPLICATE_TAG` (409) if duplicate.
- `getTags(userId)`: Returns all tags owned by the user.

#### [NEW] [journalService.js](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/backend/src/services/journalService.js)
- `createJournal(userId, data)`: Calculates `word_count` from content. Verifies `categoryId` and `tags` belong to user. Invokes `journalRepository.createEntry`.
- `getJournal(userId, journalId)`: Retrieves entry, verifies ownership, throws `ENTRY_NOT_FOUND` (404) or `ACCESS_DENIED` (403).
- `listJournals(userId, filters)`: Retrieves filtered list of active entries.
- `updateJournal(userId, journalId, data)`: Verifies ownership and matches `versionNumber` against the DB's `version_number`. If mismatched, throws `VERSION_CONFLICT` (409). Performs transaction update, creates entry version history record, and increments version.
- `deleteJournal(userId, journalId, permanent = false)`: Verifies ownership, performs soft-delete (or hard-delete if `permanent` is true).

---

### Component: Validation & Security Middleware

We will implement request schemas using Joi.

#### [NEW] [journalValidation.js](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/backend/src/validation/journalValidation.js)
Joi schemas mapping validation errors to custom API error codes (e.g. `CONTENT_REQUIRED`, `INVALID_DATE`):
- `createJournalSchema`: `title`, `content` (non-empty), `entryDate` (iso date), `categoryId`, `tags` (array of tag IDs), `isPrivate`.
- `updateJournalSchema`: Optional fields + required `versionNumber`.
- `queryJournalSchema`: Optional pagination (`page`, `limit`) and filters.

#### [NEW] [categoryValidation.js](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/backend/src/validation/categoryValidation.js)
- `createCategorySchema`: `categoryName` (non-empty string).

#### [NEW] [tagValidation.js](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/backend/src/validation/tagValidation.js)
- `createTagSchema`: `tagName` (non-empty string).

---

### Component: Controllers & Routing

#### [NEW] [journalController.js](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/backend/src/controllers/journalController.js)
HTTP endpoints mapping requests to services:
- `createJournal(req, res, next)`
- `getJournal(req, res, next)`
- `listJournals(req, res, next)`
- `updateJournal(req, res, next)`
- `deleteJournal(req, res, next)`

#### [NEW] [categoryController.js](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/backend/src/controllers/categoryController.js)
- `createCategory(req, res, next)`
- `getCategories(req, res, next)`

#### [NEW] [tagController.js](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/backend/src/controllers/tagController.js)
- `createTag(req, res, next)`
- `getTags(req, res, next)`

#### [NEW] [journalRoutes.js](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/backend/src/routes/journalRoutes.js)
Protected endpoints using `authMiddleware`:
- `POST /`
- `GET /`
- `GET /:journalId`
- `PUT /:journalId`
- `DELETE /:journalId`

#### [NEW] [categoryRoutes.js](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/backend/src/routes/categoryRoutes.js)
Protected endpoints:
- `POST /`
- `GET /`

#### [NEW] [tagRoutes.js](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/backend/src/routes/tagRoutes.js)
Protected endpoints:
- `POST /`
- `GET /`

#### [MODIFY] [app.js](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/backend/src/app.js)
Import and mount the new routes under `/api/v1`:
```javascript
app.use('/api/v1/journals', journalRoutes);
app.use('/api/v1/categories', categoryRoutes);
app.use('/api/v1/tags', tagRoutes);
```

---

### Component: Automated Tests

#### [NEW] [journal.test.js](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/backend/tests/journal.test.js)
Write integration test suites verifying:
- Successful creation of entry (201 Created) with Category and Tags, correct word count.
- Validation rejections (empty content, invalid date).
- Retrieval and filtering checks.
- Successful updates and automated creation of entry history versions.
- Optimistic locking / version mismatch conflict warning (409 Conflict).
- Soft deletion hides entries from listings, while permanent deletion removes records.
- Access control verification (preventing other users from editing or deleting entries).

#### [NEW] [metadata.test.js](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/backend/tests/metadata.test.js)
Verify Category and Tag creation, listing, duplicate detection.

---

## Verification Plan

### Automated Tests
- Run full test suite: `npm test`

### Manual Verification
- Deploy local dev server (`npm run dev`) and test endpoints using Curl/Postman commands.
