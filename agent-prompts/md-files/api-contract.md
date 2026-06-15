## API Contract Specification

**Base URL**

`/api/v1`

**Authentication**

Protected endpoints require a valid authentication token.

---

# 1. Authentication APIs

---

## POST /auth/register

### Purpose

Register a new user account.

### Request

| Field    | Type   | Required |
| -------- | ------ | -------- |
| fullName | String | Yes      |
| email    | String | Yes      |
| password | String | Yes      |

### Response

| Field         | Type   |
| ------------- | ------ |
| userId        | String |
| accountStatus | String |
| message       | String |

### Validation Rules

* Full name required.
* Email required.
* Email must be valid format.
* Email must be unique.
* Password must meet security policy.

### Status Codes

| Code | Description          |
| ---- | -------------------- |
| 201  | Account created      |
| 400  | Validation failure   |
| 409  | Email already exists |

### Error Responses

| Error Code             | Description |
| ---------------------- | ----------- |
| INVALID_EMAIL          |             |
| WEAK_PASSWORD          |             |
| DUPLICATE_EMAIL        |             |
| REQUIRED_FIELD_MISSING |             |

---

## POST /auth/login

### Purpose

Authenticate user.

### Request

| Field    | Type   | Required |
| -------- | ------ | -------- |
| email    | String | Yes      |
| password | String | Yes      |

### Response

| Field        | Type     |
| ------------ | -------- |
| accessToken  | String   |
| refreshToken | String   |
| expiresAt    | DateTime |

### Validation Rules

* Email required.
* Password required.
* Account must be verified.

### Status Codes

| Code | Description           |
| ---- | --------------------- |
| 200  | Login successful      |
| 401  | Authentication failed |

### Error Responses

| Error Code           | Description |
| -------------------- | ----------- |
| INVALID_CREDENTIALS  |             |
| ACCOUNT_NOT_VERIFIED |             |
| ACCOUNT_DISABLED     |             |

---

## POST /auth/verify-email

### Purpose

Verify newly registered account.

### Request

| Field             | Type   |
| ----------------- | ------ |
| verificationToken | String |

### Response

| Field   | Type   |
| ------- | ------ |
| status  | String |
| message | String |

### Validation Rules

* Token must exist.
* Token must not be expired.

### Status Codes

* 200 Success
* 400 Invalid Token
* 410 Expired Token

### Error Responses

* INVALID_TOKEN
* TOKEN_EXPIRED

---

## POST /auth/forgot-password

### Purpose

Initiate password reset workflow.

### Request

| Field | Type   |
| ----- | ------ |
| email | String |

### Response

| Field   | Type   |
| ------- | ------ |
| message | String |

### Validation Rules

* Valid email required.

### Status Codes

* 200 Accepted
* 400 Validation Error

### Error Responses

* INVALID_EMAIL

---

## POST /auth/reset-password

### Purpose

Reset user password.

### Request

| Field       | Type   |
| ----------- | ------ |
| resetToken  | String |
| newPassword | String |

### Response

| Field   | Type   |
| ------- | ------ |
| message | String |

### Validation Rules

* Token must be valid.
* Token must not be expired.
* Password policy enforced.

### Status Codes

* 200 Success
* 400 Validation Error
* 410 Expired Token

### Error Responses

* INVALID_TOKEN
* TOKEN_EXPIRED
* WEAK_PASSWORD

---

## POST /auth/logout

### Purpose

Terminate active session.

### Request

Authentication token required.

### Response

| Field   | Type   |
| ------- | ------ |
| message | String |

### Status Codes

* 200 Success
* 401 Unauthorized

### Error Responses

* INVALID_SESSION

---

# 2. Journal APIs

---

## GET /journals

### Purpose

Retrieve journal entries.

### Request Parameters

| Parameter | Type    |
| --------- | ------- |
| page      | Integer |
| limit     | Integer |
| startDate | Date    |
| endDate   | Date    |
| tag       | String  |
| category  | String  |
| keyword   | String  |

### Response

List of journal entries.

### Validation Rules

* User must be authenticated.
* Pagination values must be valid.

### Status Codes

* 200 Success
* 401 Unauthorized

### Error Responses

* INVALID_FILTER
* UNAUTHORIZED

---

## POST /journals

### Purpose

Create journal entry.

### Request

| Field      | Type    | Required |
| ---------- | ------- | -------- |
| title      | String  | Yes      |
| content    | String  | Yes      |
| entryDate  | Date    | Yes      |
| categoryId | String  | No       |
| tags       | Array   | No       |
| isPrivate  | Boolean | Yes      |

### Response

Created journal entry.

### Validation Rules

* Title required.
* Content required.
* Entry date required.
* Content cannot be empty.

### Status Codes

* 201 Created
* 400 Validation Error

### Error Responses

* CONTENT_REQUIRED
* INVALID_DATE

---

## GET /journals/{journalId}

### Purpose

Retrieve specific journal entry.

### Response

Journal details.

### Validation Rules

* Entry must belong to authenticated user.

### Status Codes

* 200 Success
* 404 Not Found

### Error Responses

* ENTRY_NOT_FOUND
* ACCESS_DENIED

---

## PUT /journals/{journalId}

### Purpose

Update journal entry.

### Request

| Field         | Type    |
| ------------- | ------- |
| title         | String  |
| content       | String  |
| entryDate     | Date    |
| categoryId    | String  |
| tags          | Array   |
| versionNumber | Integer |

### Response

Updated journal entry.

### Validation Rules

* Version number required.
* Version must match latest record.

### Status Codes

* 200 Updated
* 409 Version Conflict

### Error Responses

* VERSION_CONFLICT
* ENTRY_NOT_FOUND

---

## DELETE /journals/{journalId}

### Purpose

Delete journal entry.

### Request

Journal identifier.

### Response

| Field   | Type   |
| ------- | ------ |
| message | String |

### Validation Rules

* Entry ownership validation required.

### Status Codes

* 200 Deleted
* 404 Not Found

### Error Responses

* ENTRY_NOT_FOUND
* ACCESS_DENIED

---

# 3. Calendar APIs

---

## GET /calendar

### Purpose

Retrieve calendar activity information.

### Request Parameters

| Parameter | Type    |
| --------- | ------- |
| month     | Integer |
| year      | Integer |

### Response

Highlighted dates containing journal entries.

### Validation Rules

* Valid month.
* Valid year.

### Status Codes

* 200 Success

### Error Responses

* INVALID_DATE_RANGE

---

# 4. Sharing APIs

---

## POST /journals/{journalId}/share

### Purpose

Generate secure share link.

### Response

| Field      | Type   |
| ---------- | ------ |
| shareUrl   | String |
| shareToken | String |

### Validation Rules

* User must own journal.
* Entry must exist.

### Status Codes

* 201 Created

### Error Responses

* ENTRY_NOT_FOUND
* ACCESS_DENIED

---

## DELETE /journals/{journalId}/share

### Purpose

Revoke shared link.

### Response

| Field   | Type   |
| ------- | ------ |
| message | String |

### Status Codes

* 200 Revoked

### Error Responses

* SHARE_NOT_FOUND

---

## GET /share/{shareToken}

### Purpose

Access public shared journal.

### Response

View-only journal content.

### Validation Rules

* Token must be active.

### Status Codes

* 200 Success
* 404 Not Found

### Error Responses

* INVALID_SHARE_TOKEN
* SHARE_REVOKED

---

# 5. Analytics APIs

---

## GET /analytics

### Purpose

Retrieve user analytics dashboard data.

### Response

| Field           | Type    |
| --------------- | ------- |
| writingStreak   | Integer |
| totalEntries    | Integer |
| totalWords      | Integer |
| monthlyActivity | Array   |
| heatmapData     | Array   |

### Validation Rules

* Authenticated user required.

### Status Codes

* 200 Success

### Error Responses

* UNAUTHORIZED

---

# 6. Export APIs

---

## POST /export

### Purpose

Generate export request.

### Request

| Field  | Type   |
| ------ | ------ |
| format | String |

### Response

| Field    | Type   |
| -------- | ------ |
| exportId | String |
| status   | String |

### Validation Rules

* Format must be PDF or DOCX.

### Status Codes

* 202 Accepted
* 400 Validation Error

### Error Responses

* INVALID_EXPORT_FORMAT

---

## GET /export/{exportId}

### Purpose

Retrieve export status.

### Response

| Field       | Type   |
| ----------- | ------ |
| exportId    | String |
| status      | String |
| downloadUrl | String |

### Status Codes

* 200 Success
* 404 Not Found

### Error Responses

* EXPORT_NOT_FOUND

---

# 7. Draft APIs

---

## POST /drafts

### Purpose

Auto-save journal draft.

### Request

| Field     | Type   |
| --------- | ------ |
| journalId | String |
| title     | String |
| content   | String |

### Response

| Field      | Type   |
| ---------- | ------ |
| draftId    | String |
| syncStatus | String |

### Validation Rules

* Authenticated user required.

### Status Codes

* 200 Saved

### Error Responses

* SAVE_FAILED

---

## GET /drafts/{draftId}

### Purpose

Recover saved draft.

### Response

Draft details.

### Status Codes

* 200 Success
* 404 Not Found

### Error Responses

* DRAFT_NOT_FOUND

---

# 8. Tag APIs

---

## GET /tags

### Purpose

Retrieve user tags.

### Response

Tag collection.

### Status Codes

* 200 Success

---

## POST /tags

### Purpose

Create tag.

### Request

| Field   | Type   |
| ------- | ------ |
| tagName | String |

### Response

Created tag.

### Validation Rules

* Tag name required.
* Must be unique per user.

### Status Codes

* 201 Created
* 409 Duplicate

### Error Responses

* DUPLICATE_TAG

---

# 9. Category APIs

---

## GET /categories

### Purpose

Retrieve categories.

### Response

Category collection.

### Status Codes

* 200 Success

---

## POST /categories

### Purpose

Create category.

### Request

| Field        | Type   |
| ------------ | ------ |
| categoryName | String |

### Response

Created category.

### Validation Rules

* Unique category name.

### Status Codes

* 201 Created
* 409 Duplicate

### Error Responses

* DUPLICATE_CATEGORY

---

# Standard Error Response Structure

| Field     | Type     |
| --------- | -------- |
| errorCode | String   |
| message   | String   |
| timestamp | DateTime |
| requestId | String   |

---

# Security Requirements

* JWT-based authentication.
* Refresh token support.
* Password hashing.
* Token expiration enforcement.
* Ownership validation on all journal resources.
* Share token cryptographic randomness.
* Audit logging for:

  * Registration
  * Login
  * Password reset
  * Journal creation
  * Journal update
  * Journal deletion
  * Sharing
  * Export generation

---

# Performance Targets

| API                   | Target      |
| --------------------- | ----------- |
| Registration          | < 300 ms    |
| Login                 | < 300 ms    |
| Create Journal        | < 300 ms    |
| Search Journal        | < 500 ms    |
| Share Link Generation | < 300 ms    |
| Analytics API         | < 2 seconds |
| Calendar API          | < 2 seconds |
| Export Request API    | < 2 seconds |

These targets align directly with KPI-008, KPI-017, KPI-027, KPI-048, KPI-063, KPI-070, KPI-055, and KPI-094.
