# Defect Report — Sprint 3: Module 6 & Module 7

**Sprint:** Sprint 3  
**Modules:** Module 6 (Search & Filtering) | Module 7 (Calendar Navigation)  
**Tester:** Senior QA Engineer  
**Report Date:** 2026-06-11  
**Environment:** Development (localhost:5001)  

---

## Defect Summary

| Defect ID | Module | Title | Severity | Priority | Status |
|-----------|--------|-------|----------|----------|--------|
| DEF-M6-001 | Module 6 | Inverted date range (endDate < startDate) returns empty result silently instead of validation error | Medium | Medium | Open |
| DEF-M6-002 | Module 6 | No dedicated empty-state widget shown in Entries screen when search/filter returns zero results | Low | Low | Open |
| DEF-M6-003 | Module 6 / System-wide | Error responses expose full stack trace in JSON body in development mode | Medium | High | Open |

---

## Detailed Defect Reports

| Field | Details |
|-------|---------|
| **Defect ID** | DEF-M6-001 |
| **Module** | Module 6: Search & Filtering |
| **Title** | Inverted date range (endDate before startDate) returns empty result with no validation error |
| **Severity** | Medium |
| **Priority** | Medium |
| **Status** | Open |
| **Reported By** | QA Engineer |
| **Date Found** | 2026-06-11 |

**Steps to Reproduce:**
1. Authenticate with a valid user account.
2. Submit `GET /api/v1/journals?startDate=2026-12-01T00:00:00.000Z&endDate=2026-01-01T00:00:00.000Z`
3. Observe the response.

**Expected Result:**  
API returns HTTP 400 with error code `INVALID_FILTER` and message indicating the date range is invalid (endDate must be after startDate).

**Actual Result:**  
API returns HTTP 200 with an empty array `[]`. No validation error is raised. The user receives a silent empty result with no indication that their filter parameters are logically invalid.

**Root Cause (Analysis):**  
The `journalRepository.findByUser()` method applies `entry_date >= startDate AND entry_date <= endDate` conditions independently without comparing the two dates to each other. The `journalValidation.js` does not validate the relationship between `startDate` and `endDate` query parameters.

**Evidence:**
```
Request: GET /api/v1/journals?startDate=2026-12-01T00:00:00.000Z&endDate=2026-01-01T00:00:00.000Z
Response: HTTP 200 []
```

**Impacted KPI:** KPI-043 (Date range filtering), KPI-099 (Error handling returns meaningful responses)

**Recommended Fix:**  
Add cross-field validation in `journalValidation.js` or the controller:
```js
if (startDate && endDate && new Date(startDate) > new Date(endDate)) {
  throw new ApiError(400, 'INVALID_FILTER', 'startDate must be before endDate');
}
```

---

| Field | Details |
|-------|---------|
| **Defect ID** | DEF-M6-002 |
| **Module** | Module 6: Search & Filtering (Frontend) |
| **Title** | Entries screen shows blank list (no empty-state widget) when search/filter returns zero results |
| **Severity** | Low |
| **Priority** | Low |
| **Status** | Open |
| **Reported By** | QA Engineer |
| **Date Found** | 2026-06-11 |

**Steps to Reproduce:**
1. Open Journal Entries screen in the mobile app.
2. Enter a keyword in the search bar that has no matching entries (e.g., "xyznomatch").
3. Observe the entry list area.

**Expected Result:**  
A dedicated empty-state UI is displayed with an icon, message such as *"No entries found for your search"*, and an optional CTA to clear filters or create a new entry.

**Actual Result:**  
The entries list renders as empty — the `ListView.builder` with `itemCount: 0` simply shows nothing. No visual feedback is given to the user about the empty state.

**Root Cause (Analysis):**  
The `filteredEntriesProvider` data branch in `entries_screen.dart` does not include an empty-state widget when `entries.isEmpty`. The empty state for zero items is unhandled in the `data:` callback of the `AsyncValue.when()` block.

**Evidence:**  
Code inspection of `entries_screen.dart` — the `data:` callback passes entries directly to `ListView.builder` without an `isEmpty` guard.

**Impacted KPI:** KPI-046 (Empty search results display appropriate state)

**Recommended Fix:**  
Add empty state handling in `entries_screen.dart`:
```dart
data: (entries) {
  if (entries.isEmpty) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 48, color: Colors.grey),
          SizedBox(height: 12),
          Text('No entries found', style: TextStyle(color: Colors.grey)),
          TextButton(onPressed: _clearFilters, child: Text('Clear Filters')),
        ],
      ),
    );
  }
  return ListView.builder(...);
}
```

---

| Field | Details |
|-------|---------|
| **Defect ID** | DEF-M6-003 |
| **Module** | System-wide (impacts Module 6, Module 7, and all API endpoints) |
| **Title** | Error responses expose full stack traces in JSON body — production security risk |
| **Severity** | Medium |
| **Priority** | High |
| **Status** | Open |
| **Reported By** | QA Engineer |
| **Date Found** | 2026-06-11 |

**Steps to Reproduce:**
1. Trigger any API validation or server error (e.g., `GET /api/v1/calendar?year=2026` — missing month).
2. Inspect the response body JSON.

**Expected Result:**  
In production environments, error responses should only contain: `errorCode`, `message`, `timestamp`, `requestId`. Stack traces must NOT be included.

**Actual Result:**  
All error responses — including 400 and 401 errors — include a `stack` field containing the full Node.js stack trace:
```json
{
  "errorCode": "INVALID_DATE_RANGE",
  "message": "A valid month (1-12) and year are required",
  "timestamp": "...",
  "requestId": "...",
  "stack": "Error: A valid month (1-12) and year are required\n    at file:///...calendarValidation.js:31:17\n    ..."
}
```

**Root Cause (Analysis):**  
The `errorHandler` middleware in `errorHandler.js` unconditionally includes the `stack` field in the response body regardless of `NODE_ENV`. The environment check to suppress stack traces in production is either missing or not correctly implemented.

**Evidence:**
```json
"stack": "Error: Access token is required\n    at authMiddleware (file:///...authMiddleware.js:10:13)..."
```
This exposes internal file paths and function call chains to end users and potential attackers.

**Impacted KPI:** KPI-099 (Error handling returns meaningful responses), KPI-093 (Sensitive data not exposed), Security best practices.

**Recommended Fix:**  
Update `errorHandler.js` to suppress stack trace in non-development environments:
```js
res.status(statusCode).json({
  errorCode: err.errorCode || 'INTERNAL_ERROR',
  message: err.message || 'An unexpected error occurred',
  timestamp: new Date().toISOString(),
  requestId: req.id,
  ...(process.env.NODE_ENV === 'development' && { stack: err.stack })
});
```

---

## Risk Assessment

| Defect ID | Release Blocker? | Workaround Available? | Impact |
|-----------|-----------------|----------------------|--------|
| DEF-M6-001 | No (dev env) | Yes — users can swap dates manually | Silent data integrity issue — UX confusion |
| DEF-M6-002 | No | Yes — blank screen is non-functional but doesn't crash | Poor UX on zero-result searches |
| DEF-M6-003 | **Yes for production** | No — stack trace always exposed | **Security risk: internal path/code exposure in production** |

---

## Module Readiness Verdict

| Module | KPIs Covered | KPIs Passed | Open Defects | Release Ready? |
|--------|-------------|-------------|--------------|----------------|
| Module 6: Search & Filtering | KPI-040 → KPI-049 | 10/10 | 3 (1 Med, 1 Low, 1 Med/systemic) | ✅ Yes (with DEF-M6-003 fix required before prod) |
| Module 7: Calendar Navigation | KPI-050 → KPI-055 | 6/6 | 0 | ✅ Yes |

> **Production Deployment Note:** DEF-M6-003 (stack trace exposure) **must be resolved before production deployment**. This is a system-wide issue affecting all API endpoints, not just Sprint 3 modules. DEF-M6-001 and DEF-M6-002 are recommended fixes that improve quality but are not blocking.
