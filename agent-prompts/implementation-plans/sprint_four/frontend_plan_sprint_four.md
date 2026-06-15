# Implementation Plan - Sprint 4 Frontend Integration

We will connect the Sprint 4 frontend UI features in `outputs/frontend` with the real Node.js/SQLite backend endpoints for Module 8 (Journal Sharing) and Module 9 (Analytics Dashboard).

## Proposed Changes

### Component: Core Repositories & Providers

We will replace the mock analytics repository with the real backend API repository and register it in the Riverpod dependency injection container.

#### [NEW] [analytics_repository.dart](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/frontend/lib/src/core/repositories/analytics_repository.dart)
- Fetch user analytics from backend endpoint `GET /analytics`.
- Parse response fields: `writingStreak`, `totalEntries`, `totalWords`.
- Parse `heatmapData` array into Dart's expected `Map<DateTime, int>` (normalizing dates to local midnight).
- Calculate `categoryDistribution` dynamically from the passed list of `JournalEntry` objects.
- Group entries to calculate the last 6 months' dynamic word count progression `monthlyWords` for dashboard rendering.

#### [MODIFY] [providers.dart](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/frontend/lib/src/core/providers/providers.dart)
- Import `analytics_repository.dart`.
- Change type of `analyticsRepositoryProvider` from `MockAnalyticsRepository` to `AnalyticsRepository` and initialize it with `ApiClient`.

#### [MODIFY] [mock_repositories.dart](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/frontend/lib/src/core/repositories/mock_repositories.dart)
- Import `analytics_repository.dart`.
- Inherit `MockAnalyticsRepository` from `AnalyticsRepository` so that Riverpod mock overrides in tests are compiled successfully.

---

### Component: Testing & Verification

We will update widget tests to correctly mock the new `AnalyticsRepository` dependencies.

#### [MODIFY] [widget_test.dart](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/frontend/test/widget_test.dart)
- Override `analyticsRepositoryProvider` with `MockAnalyticsRepository()` in all `ProviderScope` instances to prevent real network requests during widget tests.

---

## Verification Plan

### Automated Tests
- Execute `flutter test` to verify that all widget tests compile and pass successfully.
