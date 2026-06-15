# Implementation Plan - Flutter UI Implementation with Mock Data

Implement a complete, interactive, responsive Flutter MVP UI powered by Riverpod and GoRouter. This stage connects all screens using robust **mock repositories** and populated data, enabling the testing of the entire user workflow prior to API integration.

## User Review Required

> [!NOTE]
> All screens are designed using a **Responsive layout** model. On desktop/web (width >= 800px), a left navigation sidebar is rendered. On mobile, the app automatically transitions to a bottom navigation bar or responsive drawer.
> 
> State is managed via Riverpod Providers (e.g. `journalsProvider`, `authProvider`, `analyticsProvider`). Action behaviors (creating entries, searching, filtering, toggling theme, and generating share links) are fully simulated locally.

---

## Proposed Changes

### [Frontend UI and Models]

All modifications are under [outputs/frontend](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/frontend).

#### [NEW] [models.dart](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/frontend/lib/src/core/models/models.dart)
Define Dart model structures:
- `User`: user_id, full_name, email, account_status
- `Category`: category_id, user_id, name
- `Tag`: tag_id, user_id, name
- `JournalEntry`: journal_id, user_id, category, title, content, entry_date, tags, is_private, word_count, version
- `AnalyticsData`: writing_streak, total_entries, total_words, heatmap_data (date mappings)

#### [NEW] [mock_repositories.dart](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/frontend/lib/src/core/repositories/mock_repositories.dart)
Define local mock repositories simulating latency and state:
- `MockAuthRepository`: simulates register, login, reset password, logout, and returns mock User models.
- `MockJournalRepository`: manages list of journal entries (supports search by title/content, filter by tags/categories/date range, soft delete, and auto-saving drafts).
- `MockAnalyticsRepository`: aggregates streaks, entry count, word counts, and monthly progress trends.
- `MockExportRepository`: manages export requests, status transitions (Pending -> Processing -> Completed), and download links.

#### [NEW] [providers.dart](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/frontend/lib/src/core/providers/providers.dart)
Riverpod providers exposing repositories and state:
- `authProvider` (StateNotifier managing current session User)
- `journalsProvider` (StateNotifier managing list of entries)
- `searchQueryProvider`, `tagFilterProvider`, `categoryFilterProvider`
- `analyticsProvider` (FutureProvider loading streaks and metrics)
- `themeModeProvider` (StateNotifier toggling theme modes)

#### [NEW] [responsive_layout.dart](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/frontend/lib/src/core/widgets/responsive_layout.dart)
Utility widget to wrap views, executing different builders for mobile vs desktop screen bounds (breakpoint: 800px).

#### [NEW] [main_shell.dart](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/frontend/lib/src/features/dashboard/presentation/main_shell.dart)
Unified layout scaffold containing:
- Left sidebar for Desktop/Web (240px wide) featuring user profile, module links, and logout.
- Bottom navigation bar on Mobile.

#### [NEW] [auth_screens.dart](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/frontend/lib/src/features/auth/presentation/auth_screens.dart)
Implement interactive authentication screens:
- **LoginScreen**: Input fields for email/password, validations, login button (with loading simulator), and sign-up/password-reset redirects.
- **RegisterScreen**: Full registration form enforcing strong password policies.
- **ForgotPasswordScreen**: Simulation of sending password-reset link and token-based reset verification.

#### [NEW] [dashboard_screen.dart](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/frontend/lib/src/features/dashboard/presentation/dashboard_screen.dart)
Landing dashboard. Displays quick stats cards (streak, entries, words), recent entries list, category filters, and writing prompt buttons.

#### [NEW] [entries_screen.dart](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/frontend/lib/src/features/journal/presentation/entries_screen.dart)
Journal browser displaying cards:
- Full text search input
- Expandable filters drawer (Categories, Tags, Date Range picker)
- List of matching entries with highlights, category labels, and tags.

#### [NEW] [editor_screen.dart](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/frontend/lib/src/features/journal/presentation/editor_screen.dart)
Clean, distraction-free writing environment:
- Text inputs for title and content
- Text formatting toolbar (Bold, Italic, Bullets) simulating rich text editor behavior
- Dynamic word counter and auto-save notification indicator
- Categories & tags assignment selectors
- Privacy toggle (Public/Private Share link generator).

#### [NEW] [entry_details_screen.dart](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/frontend/lib/src/features/journal/presentation/entry_details_screen.dart)
Reading screen showing formatted entry content, metadata, edit/delete actions, and a secure public sharing url generation sheet (active toggle).

#### [NEW] [calendar_screen.dart](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/frontend/lib/src/features/journal/presentation/calendar_screen.dart)
Visual calendar layout integrating `table_calendar` to mark active writing dates, allowing day-to-day timeline browsing of journal history.

#### [NEW] [analytics_screen.dart](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/frontend/lib/src/features/analytics/presentation/analytics_screen.dart)
Dashboard with:
- Heatmap calendar grid displaying activity density
- Horizontal progress bar charts showing category distribution
- Line chart of monthly word count statistics.

#### [NEW] [export_screen.dart](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/frontend/lib/src/features/export/presentation/export_screen.dart)
Interface to trigger PDF/DOCX exports, tracking asynchronous job queue states with simulation timer and listing historical files downloads.

#### [NEW] [settings_screen.dart](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/frontend/lib/src/features/settings/presentation/settings_screen.dart)
App configuration screen. Custom category/tag manager (add, delete options) and theme toggle buttons.

#### [MODIFY] [router.dart](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/frontend/lib/src/config/router.dart)
Configure GoRouter to support all sub-routes inside the ShellRoute of the dashboard:
- `/login`, `/register`, `/forgot-password`
- Dashboard shell containing:
  - `/` (Dashboard)
  - `/journals` (List of entries)
  - `/journals/create` (Editor)
  - `/journals/:id` (Details)
  - `/journals/:id/edit` (Editor)
  - `/calendar` (Calendar)
  - `/analytics` (Analytics)
  - `/export` (Export)
  - `/settings` (Settings)

#### [MODIFY] [app.dart](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/frontend/lib/src/app.dart)
Configure MaterialApp to read light/dark/system themes matching the `themeModeProvider` provider state.

---

## Verification Plan

### Automated Tests
- Run `flutter analyze` to ensure strict typing and compile-time correctness.
- Update widget tests in `test/widget_test.dart` to verify routing navigation and Riverpod provider values.
- Run `flutter test` to execute all tests.

### Manual Verification
- Compile and run the Flutter application on Chrome Web (`flutter run -d chrome`).
- Verify routing transitions: login -> forgot password -> login -> register -> dashboard.
- Test all journal interactions: adding entries, tagging, modifying categories, search filtering, and generating share links.
- Toggle dark/light themes inside settings and verify design system colors adapt correctly.
