# Implementation Plan - Sprint 3 Frontend Integration (Search & Filtering, Calendar Navigation)

We will integrate Sprint 3 frontend features in `outputs/frontend` with the real Node.js/SQLite backend endpoints.

## Proposed Changes

### Component: Core Repositories & Models

We will update the frontend `JournalRepository` and `MockJournalRepository` to connect with backend endpoints.

#### [MODIFY] [journal_repository.dart](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/frontend/lib/src/core/repositories/journal_repository.dart)
- Update `getEntries` to accept optional query parameters: `keyword`, `categoryId`, `tagId`, `startDate`, and `endDate`. Construct `queryParameters` map and pass to `_apiClient.dio.get('/journals', queryParameters: ...)`.
- Add new method `Future<List<String>> getCalendarDates(int month, int year)` to fetch highlighted dates containing journal entries via `GET /calendar?month=x&year=y`.

#### [MODIFY] [mock_repositories.dart](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/frontend/lib/src/core/repositories/mock_repositories.dart)
- Update `MockJournalRepository.getEntries` to accept the same parameters and perform mock filter evaluations in-memory for backward compatibility and testing.
- Implement `getCalendarDates` in `MockJournalRepository` returning distinct mock date strings (`YYYY-MM-DD`) from mock entries for the selected month/year.

---

### Component: State Management (Riverpod Providers)

We will update Riverpod providers to support server-side filtering, calendar pagination, and selected day fetching.

#### [MODIFY] [providers.dart](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/frontend/lib/src/core/providers/providers.dart)
- Create `allEntriesProvider` which always fetches all entries unfiltered (used by Analytics and to keep dashboard entries independent).
- Update `recentEntriesProvider` to extract the 3 most recent entries from `allEntriesProvider`.
- Update `journalsProvider` / `JournalsNotifier` to watch search/filter state providers (`searchQueryProvider`, `selectedCategoryFilterProvider`, `selectedTagFilterProvider`, `selectedDateRangeFilterProvider`) and pass them to the repository `getEntries(...)` call.
- Update `filteredEntriesProvider` to simply expose `ref.watch(journalsProvider)` since filtering is performed on the server.
- Add `calendarDatesProvider` as a `FutureProvider.family<List<String>, String>` which queries `getCalendarDates(month, year)` by parsing a `"YYYY-MM"` parameter.
- Add `calendarEntriesProvider` as a `FutureProvider.family<List<JournalEntry>, DateTime>` which queries `getEntries(...)` for a single date range.

---

### Component: UI Presentation Screens

We will update calendar navigation and main dashboard screens to interact with new providers.

#### [MODIFY] [calendar_screen.dart](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/frontend/lib/src/features/journal/presentation/calendar_screen.dart)
- Watch `calendarDatesProvider` using current `_focusedDay` (e.g. `"${_focusedDay.year}-${_focusedDay.month}"`) to get highlighted date strings.
- Watch `calendarEntriesProvider` using `_selectedDay` to display entries for the selected day.
- Update `TableCalendar`'s `eventLoader` to query whether the formatted day string exists in the fetched list of highlighted dates.
- Gracefully handle loading and error states for both the calendar highlights and the bottom daily entries list.

#### [MODIFY] [dashboard_screen.dart](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/frontend/lib/src/features/dashboard/presentation/dashboard_screen.dart)
- Watch `recentEntriesProvider` instead of `journalsProvider` to keep the dashboard isolated from active filters on the Entries screen.
- Invalidate `allEntriesProvider` (which cascades to `recentEntriesProvider` and `analyticsProvider`) on refresh.

---

## Verification Plan

### Automated Tests
- Run Flutter tests: `flutter test` to ensure all existing widget tests pass successfully and no regressions are introduced.
- Write new widget/integration test cases in a new test file or inside `widget_test.dart` to cover calendar navigation and search/filtering with real/mock repositories.

### Manual Verification
- Verify the calendar highlights and search features visually or using logs to verify that backend requests are made.
