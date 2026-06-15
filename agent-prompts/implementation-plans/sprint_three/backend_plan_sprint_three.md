# Implementation Plan - Sprint 3 Backend Modules (Search & Filtering, Calendar Navigation)

We will implement Sprint 3 backend features under `outputs/backend`. 
- **Module 6: Search & Filtering** is already fully integrated into the existing `GET /journals` endpoint. We will write explicit test coverage for it.
- **Module 7: Calendar Navigation** requires a new `/calendar` endpoint returning dates of journal entries for a given month and year.

## Proposed Changes

### Component: Database & Repositories

We will add a new query method to the existing `journalRepository.js`.

#### [MODIFY] [journalRepository.js](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/backend/src/repositories/journalRepository.js)
Add method:
- `findDatesByMonthAndYear(userId, month, year)`: Queries distinct active `entry_date` values for a user during a specific month and year, normalizing them to `YYYY-MM-DD` strings.

---

### Component: Services & Validation

We will create validation schemas and services for calendar calculations.

#### [NEW] [calendarValidation.js](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/backend/src/validation/calendarValidation.js)
Define a Joi schema and middleware:
- `getCalendarSchema`: Validates query parameters: `month` (1-12 integer) and `year` (integer).
- `validateQuery(schema)`: Validation middleware for `req.query`, returning `INVALID_DATE_RANGE` (400) if validation fails.

#### [NEW] [calendarService.js](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/backend/src/services/calendarService.js)
- `getHighlightedDates(userId, month, year)`: Calls repository to fetch normalized dates for the user.

---

### Component: Controllers & Routing

We will create the calendar controller and router, and mount them in the Express application.

#### [NEW] [calendarController.js](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/backend/src/controllers/calendarController.js)
- `getCalendar(req, res, next)`: Handles the endpoint request and returns the list of highlighted dates.

#### [NEW] [calendarRoutes.js](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/backend/src/routes/calendarRoutes.js)
Expose endpoint under JWT session protection:
- `GET /` -> protected by `authMiddleware`, validates query with `calendarValidation.validateQuery`, calls `calendarController.getCalendar`.

#### [MODIFY] [app.js](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/backend/src/app.js)
- Import `calendarRoutes` and mount under `/api/v1/calendar`.

---

### Component: Automated Tests

#### [NEW] [calendar.test.js](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/backend/tests/calendar.test.js)
Write integration test suites verifying:
- Successful retrieval of highlighted dates (200 OK) for a user.
- Correct date filtering for the selected month/year.
- Validation failures (e.g. missing month/year, values out of bounds) return 400 Bad Request with `INVALID_DATE_RANGE`.
- Access control validation (a user only sees their own active dates).

---

## Verification Plan

### Automated Tests
- Run Express tests: `npm test`
