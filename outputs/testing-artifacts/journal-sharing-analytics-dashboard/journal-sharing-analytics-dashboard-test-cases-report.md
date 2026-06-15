# Module 8: Journal Sharing — Test Cases Report
# Module 9: Analytics Dashboard — Test Cases Report

**Sprint:** Sprint 4  
**Tester:** Senior QA Engineer  
**Test Execution Date:** 2026-06-11  
**Backend Version:** Node.js/Express — Port 5001  
**Frontend Version:** Flutter (Riverpod State Management)  
**Environment:** Development  

---

## Scope

This report covers functional, integration, validation, security, and performance testing for:

- **Module 8:** Journal Sharing (KPI-056 → KPI-063)
- **Module 9:** Analytics Dashboard (KPI-064 → KPI-071)

---

# Module 8: Journal Sharing

## Validation Functions Table

| KPI Number | KPI | Validation Method | Expected Output | Actual Output | Status | Notes |
|------------|-----|-------------------|-----------------|---------------|--------|-------|
| KPI-056 | User can successfully generate secure share link for their own entry | Submit `POST /api/v1/journals/:journalId/share` with valid auth token; verify response contains `shareUrl` and `shareToken` | HTTP 201 response with `shareUrl` and `shareToken` | HTTP 201 response with valid URL and token | ✅ PASS | Share token generated successfully, URL points to public shared route |
| KPI-057 | Share link generation returns 404 for nonexistent journal | Submit `POST /api/v1/journals/j-nonexistent/share` with valid auth token | HTTP 404 with errorCode `ENTRY_NOT_FOUND` | HTTP 404 with `ENTRY_NOT_FOUND` | ✅ PASS | Graceful validation of nonexistent entries |
| KPI-058 | Share link generation enforces ownership validation | Submit `POST /api/v1/journals/:journalId/share` using User 2's token on User 1's entry | HTTP 403 with errorCode `ACCESS_DENIED` | HTTP 403 with `ACCESS_DENIED` | ✅ PASS | Strictly prevents unauthorized sharing of another user's entry |
| KPI-059 | Shared link allows public view-only access | Submit `GET /api/v1/share/:shareToken` without auth header; verify response | HTTP 200 with journal details (title, content, entryDate, wordCount) | HTTP 200 with view-only journal details, no auth required | ✅ PASS | View-only projection excludes private metadata |
| KPI-060 | Accessing public route with invalid token returns 400/404 | Submit `GET /api/v1/share/nonexistent-token` | HTTP 404 with errorCode `INVALID_SHARE_TOKEN` | HTTP 404 with `INVALID_SHARE_TOKEN` | ✅ PASS | Invalid tokens handled gracefully |
| KPI-061 | Shared link revocation works and invalidates subsequent requests | Submit `DELETE /api/v1/journals/:journalId/share`; then access `GET /api/v1/share/:shareToken` | HTTP 200 Revoked; then GET returns HTTP 404 `SHARE_REVOKED` | HTTP 200 Revoked; then GET returns HTTP 404 with `SHARE_REVOKED` | ✅ PASS | Share link status correctly deactivated and updated in DB |
| KPI-062 | Share token uses cryptographically secure UUIDv4 | Check share link format returned by API | Token is a valid v4 UUID string, preventing enumeration | Token format matches UUIDv4 pattern | ✅ PASS | Highly secure token pattern |
| KPI-063 | Share link generation and access perform within 300ms | Measure response times for share generation and access | Average response time < 300ms | Average response time ~5-12ms | ✅ PASS | Performant local SQLite queries |

---

## Additional Test Cases — Module 8

| Test ID | Test Case | Test Steps | Expected | Actual | Status |
|---------|-----------|------------|----------|--------|--------|
| TC-M8-SEC-01 | Unauthenticated share creation rejected | Call `POST /api/v1/journals/:journalId/share` without Authorization header | HTTP 401 UNAUTHORIZED | HTTP 401 `{"errorCode":"UNAUTHORIZED","message":"Access token is required"}` | ✅ PASS |
| TC-M8-SEC-02 | Unauthenticated share revocation rejected | Call `DELETE /api/v1/journals/:journalId/share` without Authorization header | HTTP 401 UNAUTHORIZED | HTTP 401 with unauthorized message | ✅ PASS |
| TC-M8-SEC-03 | Audit log entry created on share link generation | Generate share link; query `AuditLog` table | Record with `action_type = 'Share'` created | Audit log entry present in database with token details | ✅ PASS |
| TC-M8-SEC-04 | Audit log entry created on share link revocation | Revoke share link; query `AuditLog` table | Record with `action_type = 'RevokeShare'` created | Audit log entry present in database | ✅ PASS |
| TC-M8-INT-01 | Sharing UI handles loading and error states | Click "Share" button in frontend; simulate delay/failure | Progress indicator displayed; Snackbar error shown on failure | `_isGeneratingLink` manages state; Snackbar displays on error | ✅ PASS |
| TC-M8-INT-02 | Soft-deleted journals are not accessible via shared link | Soft-delete a shared journal; access public shared link | HTTP 404 ENTRY_NOT_FOUND returned | HTTP 404 with `ENTRY_NOT_FOUND` | ✅ PASS |

---

# Module 9: Analytics Dashboard

## Validation Functions Table

| KPI Number | KPI | Validation Method | Expected Output | Actual Output | Status | Notes |
|------------|-----|-------------------|-----------------|---------------|--------|-------|
| KPI-064 | Dashboard shows correct entry count | Submit `GET /api/v1/analytics` with valid auth; compare `totalEntries` with count in DB | `totalEntries` matches active entry count | `totalEntries` equals 3 (matches DB count) | ✅ PASS | Excludes soft-deleted entries |
| KPI-065 | Dashboard shows correct word count | Compare `totalWords` from analytics response with sum of words in DB | `totalWords` matches sum in DB | `totalWords` equals 9 (matches DB sum) | ✅ PASS | Correctly aggregates word counts on active entries |
| KPI-066 | Dashboard shows correct writing streak count | Insert 3 consecutive daily entries; verify `writingStreak` equals 3 | `writingStreak` equals 3 | `writingStreak` is 3 | ✅ PASS | Correctly detects consecutive days |
| KPI-067 | Writing streak handles broken streaks correctly | Insert entries with a gap (skip a day); verify streak counts from end of gap | Streak resets/counts from newest date only | Streak resets to 1 (considers gap) | ✅ PASS | Streak resets correctly |
| KPI-068 | Monthly activity returned correctly | Verify `monthlyActivity` matches active monthly counts | Array of objects with `month` and `count` | June 2026 month count is 3 | ✅ PASS | Groups by month `YYYY-MM` correctly |
| KPI-069 | Heatmap data returned correctly | Verify `heatmapData` matches daily active entries | Array of objects with `date` and `count` | June 9, 10, 11 contain count = 1 | ✅ PASS | Groups by day `YYYY-MM-DD` correctly |
| KPI-070 | Analytics API requires authentication | Submit `GET /api/v1/analytics` without token | HTTP 401 UNAUTHORIZED | HTTP 401 `{"errorCode":"UNAUTHORIZED","message":"Access token is required"}` | ✅ PASS | Enforces authMiddleware checks |
| KPI-071 | Analytics API processes within 2 seconds | Measure response time for `GET /api/v1/analytics` | Response time < 2000ms | Average response time ~12ms | ✅ PASS | Efficient aggregation query performance |

---

## Additional Test Cases — Module 9

| Test ID | Test Case | Test Steps | Expected | Actual | Status |
|---------|-----------|------------|----------|--------|--------|
| TC-M9-VAL-01 | Analytics for user with zero entries | Call analytics for new user with no journal entries | Returns all counts at 0 and empty arrays | `totalEntries:0, totalWords:0, writingStreak:0, monthlyActivity:[], heatmapData:[]` | ✅ PASS |
| TC-M9-VAL-02 | Analytics excludes deleted entries | Soft-delete an entry; re-query analytics | counts, streak, and monthly stats exclude deleted entry | Counts decrease by 1; stats updated | ✅ PASS |
| TC-M9-INT-01 | Progress chart displays dynamic monthly word counts | View progress chart on analytics screen | Displays dynamic sums for last 6 months | Chart bars render correct proportions | ✅ PASS |
| TC-M9-INT-02 | Category distribution chart renders correct ratios | View category chart on analytics screen | Displays correct category count divisions | Chart slices represent actual categories | ✅ PASS |
| TC-M9-INT-03 | Heatmap widget renders calendar counts | View calendar heatmap on analytics screen | Highlighted cells match active dates | Highlighted dates match heatmapData date keys | ✅ PASS |

---

## Test Environment

| Parameter | Value |
|-----------|-------|
| Backend URL | http://localhost:5001/api/v1 |
| Database | SQLite (journal.db) |
| Testing Tool | Jest, Supertest, Flutter Integration Driver |
| OS Version | macOS |
