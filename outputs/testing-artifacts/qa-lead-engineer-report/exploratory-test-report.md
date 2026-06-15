# QA Lead Exploratory Test Report

**Report Date:** 2026-06-12  
**Tester:** Senior QA Lead Engineer  
**UAT Environment:** Local Development Environment  

---

## 1. Executive Summary

This report documents findings from **Exploratory, Chaos, and Destructive Testing** conducted on the Journal Hub application. The goal of this testing mode is to go beyond structured scripts, simulating realistic user behaviors, concurrent operations, and network degradation to uncover edge-case defects and stability risks.

---

## 2. Test Coverage & Scenarios

| Scenario ID | Test Type | Scenario Description | Expected Result | Actual Result | Status |
|-------------|-----------|----------------------|-----------------|---------------|--------|
| **EXP-001** | Chaos / Network | Disconnect network during rapid editor inputs; trigger auto-save. | App continues to operate; auto-save falls back to SharedPreferences local storage; no crashes. | Orange SnackBar alert displayed; status icon changes to orange cloud_off_rounded; draft saved locally. | ✅ PASS |
| **EXP-002** | Destructive / OCC | Open the same journal entry in two separate sessions and save edits sequentially. | First edit succeeds; second edit is rejected with a version mismatch error to prevent overwrites. | HTTP 409 conflict returned; UI correctly prevents data loss. | ✅ PASS |
| **EXP-003** | Security / Injection | Inject SQL syntax (`' OR '1'='1`) and script blocks (`<script>alert(1)</script>`) into search/title fields. | Queries fail safely without database corruption, SQL exposure, or XSS execution. | Queries escaped successfully; no SQL errors or script executions observed. | ✅ PASS |
| **EXP-004** | Chaos / Rate Limit | Execute rapid login calls (brute force) from the same IP client. | Authentication rate limiter blocks requests after limit threshold (20 attempts/hr). | HTTP 429 returned with `AUTH_RATE_LIMIT_EXCEEDED` message. | ✅ PASS |
| **EXP-005** | Usability / Rotation | Rapidly rotate emulator viewports while calendar/analytics panels are loading. | Layout recalculates dynamically; no UI freeze or content overlaps. | Scroll views recalculate and fit layout without overlapping text. | ✅ PASS |

---

## 3. Key Findings & Analysis

### A. Network Interruption & Recovery
* **Behavior**: The application demonstrates robust recovery when connectivity is lost and regained. SharedPreferences draft preservation caching ensures edits are never lost, and the next keystroke immediately syncs changes back to the remote Express server after reconnection.
* **UX Polish**: The orange status indicators and the transient SnackBar warning provide clear, premium micro-animations and warnings that meet high usability benchmarks.

### B. Security & Rate Limiting
* **API Protection**: Security headers (`helmet`) and CORS origin checking block unauthorized cross-site requests. Passwords remain salted and hashed using `bcrypt` across all databases.
* **Audit Trail Gap**: While sharing and exports log metadata correctly, user-facing security operations (e.g. login failures, account additions) are not audited. This is documented in `DEF-M13-001`.

---

## 4. Recommendations
1. **Fix Audit Logs (DEF-M13-001)**: Implement audit trail hooks inside the authentication and journal creation/edit controller flows to capture user-origin audit logs.
2. **Offline indicator retention**: Ensure that when the app restarts in offline mode, it retains the local draft status badge from the first initialization.
