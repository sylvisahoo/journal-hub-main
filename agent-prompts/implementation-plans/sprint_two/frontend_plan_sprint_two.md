# Implementation Plan - Sprint 2 Frontend Integration (Journal Creation, Editing, Deletion)

We will connect the Flutter client UI to the real Node.js Express backend APIs for Sprint 2 (Module 3: Journal Entry Creation, Module 4: Journal Entry Editing, and Module 5: Journal Entry Deletion), ensuring all components interact with the live database and REST endpoints.

## User Review Required

> [!IMPORTANT]
> The backend does not implement endpoints for deleting categories or deleting tags. Therefore, `deleteCategory` and `deleteTag` will behave as no-ops in the production `JournalRepository` (similar to how they are handled on the backend).

## Proposed Changes

### Component: Core Repositories & Providers

We will implement a real API-backed `JournalRepository` and update Riverpod providers.

#### [NEW] [journal_repository.dart](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/frontend/lib/src/core/repositories/journal_repository.dart)
Create a production repository mapping local model calls to REST API requests:
- Class fields: `List<Category> categories` and `List<Tag> tags` representing the loaded metadata cache.
- `loadMetadata()`: Asynchronously runs concurrent requests to load categories and tags, populating the cache.
- `getEntries()`: Queries `GET /journals`. Deserializes API response array into a list of `JournalEntry` models.
- `createEntry(JournalEntry entry)`: Queries `POST /journals` with camelCase payload: `title`, `content`, `entryDate`, `categoryId`, `tags`, `isPrivate`.
- `updateEntry(JournalEntry entry)`: Queries `PUT /journals/:journalId` with payload including `versionNumber` to support optimistic locking.
- `deleteEntry(String journalId)`: Queries `DELETE /journals/:journalId`.
- `createCategory(String name)`: Queries `POST /categories` with payload `{ categoryName: name }`.
- `createTag(String name)`: Queries `POST /tags` with payload `{ tagName: name }`.
- `deleteCategory(String categoryId)` & `deleteTag(String tagId)`: Fallback no-op methods (as API deletion endpoints do not exist).

#### [MODIFY] [providers.dart](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/frontend/lib/src/core/providers/providers.dart)
- Replace `MockJournalRepository` references with `JournalRepository`.
- Register `journalRepositoryProvider` as `Provider<JournalRepository>`.
- In `JournalsNotifier`, call `await _repo.loadMetadata()` in `loadEntries()` before retrieving journal entries, ensuring category/tag caches are populated on app load and refresh.

---

### Component: Testing

#### [MODIFY] [widget_test.dart](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/frontend/test/widget_test.dart)
- Explicitly override `journalRepositoryProvider` with `MockJournalRepository` within all test cases to prevent widget tests from making network calls to localhost.

---

## Verification Plan

### Automated Tests
- Run all backend integration tests to ensure API stability: `npm test` (inside backend directory)
- Run all frontend widget tests to verify UI flows function with mocks: `flutter test` (inside frontend directory)

### Manual Verification
- Launch Express backend locally: `npm run dev` (already running)
- Launch Flutter Web or Android Emulator/Simulator client.
- Create new categories and tags in settings.
- Add and edit journals, verify categories and tags list selection renders correctly and persists.
- Delete a journal and verify it disappears from the list.
