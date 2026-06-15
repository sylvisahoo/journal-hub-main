# Implementation Plan - Sprint 4 Backend (Journal Sharing & Analytics Dashboard)

We will implement the backend logic, repositories, services, controllers, and routing for Module 8 (Journal Sharing) and Module 9 (Analytics Dashboard).

## User Review Required

> [!IMPORTANT]
> - **Authentication**: Journal sharing public endpoint `GET /api/v1/share/:shareToken` will bypass authentication to allow view-only access, while link generation (`POST /api/v1/journals/:journalId/share`) and revocation (`DELETE /api/v1/journals/:journalId/share`) will strictly enforce ownership validation.
> - **Audit Logging**: As per security requirements, we will implement audit logging for both share link generation and revocation by writing to the `AuditLog` table.
> - **Writing Streak Algorithm**: The writing streak is calculated on-the-fly from the user's active (non-deleted) journal entries, counting consecutive days backwards from the most recent entry if it was today or yesterday.

## Proposed Changes

### Component: Database & Repositories

We will implement repository files for managing shared links and gathering user analytics.

#### [NEW] [shareRepository.js](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/backend/src/repositories/shareRepository.js)
- `createShare(shareId, journalId, shareToken)`: Insert a new share record into the `JournalShare` table (defaulting `is_active` to 1).
- `findActiveByJournalId(journalId)`: Find an active share link for a specific journal.
- `findByToken(shareToken)`: Find a share record by its token.
- `deactivateSharesByJournalId(journalId)`: Deactivate any active share links for a specific journal (sets `is_active = 0` and `revoked_at = CURRENT_TIMESTAMP`).

#### [NEW] [analyticsRepository.js](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/backend/src/repositories/analyticsRepository.js)
- `getBasicStats(userId)`: Query the total count of non-deleted entries and the sum of word counts.
- `getDistinctEntryDates(userId)`: Query distinct `entry_date` values for streak calculations, sorted descending.
- `getMonthlyActivity(userId)`: Query entry counts grouped by month (format: `YYYY-MM`).
- `getHeatmapData(userId)`: Query entry counts grouped by day (format: `YYYY-MM-DD`).

---

### Component: Service Layer

We will implement services containing the business logic for sharing validation and analytics calculation.

#### [NEW] [shareService.js](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/backend/src/services/shareService.js)
- `generateShareLink(userId, journalId, hostUrl)`: Validate journal existence and ownership. Generate a secure UUIDv4 token. Deactivate any existing active shares. Insert a new active `JournalShare` record and write a 'Share' entry into the `AuditLog`. Return the share URL and token.
- `revokeShareLink(userId, journalId)`: Validate journal existence and ownership. Deactivate any active shares. Write a 'RevokeShare' entry into the `AuditLog`.
- `getPublicEntry(shareToken)`: Look up active share by token. If not found or inactive, check if a revoked record exists to throw `SHARE_REVOKED` or `INVALID_SHARE_TOKEN`. Fetch the corresponding journal (ensuring it is not deleted) and return its view-only details.

#### [NEW] [analyticsService.js](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/backend/src/services/analyticsService.js)
- `getUserAnalytics(userId)`: Retrieve user stats and entry dates from the repository. Compute the current consecutive writing streak. Aggregate the monthly activity and daily heatmap data. Return the compiled response payload.

---

### Component: Controller & Route Layer

We will expose the APIs by mapping the HTTP requests to services.

#### [NEW] [shareController.js](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/backend/src/controllers/shareController.js)
- `generateShareLink`: Extract journal ID, call service, return 201 with `{ shareUrl, shareToken }`.
- `revokeShareLink`: Extract journal ID, call service, return 200 with success message.
- `getPublicEntry`: Extract token, call service, return 200 with view-only journal data.

#### [NEW] [analyticsController.js](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/backend/src/controllers/analyticsController.js)
- `getAnalytics`: Call `analyticsService.getUserAnalytics` with current `userId`, return 200 with analytics payload.

#### [MODIFY] [journalRoutes.js](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/backend/src/routes/journalRoutes.js)
- Register `POST /:journalId/share` -> `shareController.generateShareLink`
- Register `DELETE /:journalId/share` -> `shareController.revokeShareLink`

#### [NEW] [shareRoutes.js](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/backend/src/routes/shareRoutes.js)
- Expose public endpoint `GET /:shareToken` -> `shareController.getPublicEntry` (without auth middleware).

#### [NEW] [analyticsRoutes.js](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/backend/src/routes/analyticsRoutes.js)
- Expose authenticated endpoint `GET /` -> `analyticsController.getAnalytics`.

#### [MODIFY] [app.js](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/backend/src/app.js)
- Import and mount `shareRoutes` on `/api/v1/share`.
- Import and mount `analyticsRoutes` on `/api/v1/analytics`.

---

## Verification Plan

### Automated Tests
- Create `outputs/backend/tests/share.test.js`:
  - Test generating a share link (must return 201, valid UUIDv4 token, and constructed URL).
  - Test accessing the public shared entry (must return 200 with correct fields, view-only).
  - Test accessing with invalid token (must return 404 with `INVALID_SHARE_TOKEN`).
  - Test revoking a share link (must return 200, verify future access returns 404 with `SHARE_REVOKED`).
  - Test ownership checks (cannot share or revoke another user's journal).
  - Test that AuditLogs are successfully created.
- Create `outputs/backend/tests/analytics.test.js`:
  - Test retrieving user analytics.
  - Test correct word count, entry count, monthly activity, and heatmap structure.
  - Test streak calculation logic (consecutive days vs broken streak).
  - Test unauthenticated requests return 401.

### Manual Verification
- Execute tests using `npm test` inside `outputs/backend`.
- Verify the server loads successfully on port 5001.
