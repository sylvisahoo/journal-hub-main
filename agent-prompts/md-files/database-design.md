## Database Design Specification

**Database:** SQLite

---

# 1. Entity List

The database design supports all functional and non-functional requirements defined in the project scope and KPI specification.

### Core Entities

1. User
2. UserSession
3. PasswordResetToken
4. EmailVerificationToken
5. JournalEntry
6. JournalEntryVersion
7. Category
8. Tag
9. JournalTag
10. JournalShare
11. AnalyticsSnapshot
12. ExportRequest
13. ExportFile
14. Notification
15. Draft
16. AuditLog

---

# 2. Table Definitions

## User

Stores account and profile information.

## UserSession

Stores authenticated session and refresh token information.

## PasswordResetToken

Stores password reset workflow tokens.

## EmailVerificationToken

Stores account verification tokens.

## JournalEntry

Stores journal content and metadata.

## JournalEntryVersion

Stores entry version history for edit conflict detection and recovery.

## Category

Stores journal categories.

## Tag

Stores user-defined tags.

## JournalTag

Many-to-many relationship between journal entries and tags.

## JournalShare

Stores public sharing configuration and share tokens.

## AnalyticsSnapshot

Stores aggregated analytics metrics.

## ExportRequest

Tracks export generation requests.

## ExportFile

Stores generated export metadata and download links.

## Notification

Stores system-generated notifications.

## Draft

Stores recoverable drafts and offline synchronization data.

## AuditLog

Stores security and compliance audit records.

---

# 3. Column Definitions

## User

| Column         | Data Type | Description                 |
| -------------- | --------- | --------------------------- |
| user_id        | UUID/Text | Unique user identifier      |
| full_name      | Text      | User full name              |
| email          | Text      | Unique email address        |
| password_hash  | Text      | Encrypted password          |
| account_status | Text      | Pending, Verified, Disabled |
| created_at     | DateTime  | Creation timestamp          |
| updated_at     | DateTime  | Last update timestamp       |
| last_login_at  | DateTime  | Last successful login       |

---

## UserSession

| Column        | Data Type | Description           |
| ------------- | --------- | --------------------- |
| session_id    | UUID/Text | Session identifier    |
| user_id       | UUID/Text | Owner user            |
| access_token  | Text      | Authentication token  |
| refresh_token | Text      | Refresh token         |
| expires_at    | DateTime  | Expiration timestamp  |
| created_at    | DateTime  | Session creation time |
| is_active     | Boolean   | Session status        |

---

## PasswordResetToken

| Column     | Data Type | Description        |
| ---------- | --------- | ------------------ |
| reset_id   | UUID/Text | Reset identifier   |
| user_id    | UUID/Text | Associated user    |
| token      | Text      | Reset token        |
| expires_at | DateTime  | Token expiration   |
| used_at    | DateTime  | Usage timestamp    |
| created_at | DateTime  | Creation timestamp |

---

## EmailVerificationToken

| Column          | Data Type | Description             |
| --------------- | --------- | ----------------------- |
| verification_id | UUID/Text | Verification identifier |
| user_id         | UUID/Text | Associated user         |
| token           | Text      | Verification token      |
| expires_at      | DateTime  | Expiration time         |
| verified_at     | DateTime  | Verification timestamp  |
| created_at      | DateTime  | Creation timestamp      |

---

## Category

| Column        | Data Type | Description         |
| ------------- | --------- | ------------------- |
| category_id   | UUID/Text | Category identifier |
| user_id       | UUID/Text | Owner user          |
| category_name | Text      | Category name       |
| created_at    | DateTime  | Creation timestamp  |

---

## Tag

| Column     | Data Type | Description        |
| ---------- | --------- | ------------------ |
| tag_id     | UUID/Text | Tag identifier     |
| user_id    | UUID/Text | Owner user         |
| tag_name   | Text      | Tag value          |
| created_at | DateTime  | Creation timestamp |

---

## JournalEntry

| Column         | Data Type | Description                |
| -------------- | --------- | -------------------------- |
| journal_id     | UUID/Text | Journal identifier         |
| user_id        | UUID/Text | Owner user                 |
| category_id    | UUID/Text | Optional category          |
| title          | Text      | Entry title                |
| content        | Text      | Rich text content          |
| entry_date     | Date      | Journal date               |
| word_count     | Integer   | Calculated word count      |
| is_private     | Boolean   | Privacy flag               |
| version_number | Integer   | Optimistic locking version |
| created_at     | DateTime  | Creation timestamp         |
| updated_at     | DateTime  | Update timestamp           |
| deleted_at     | DateTime  | Soft delete timestamp      |

---

## JournalEntryVersion

| Column         | Data Type | Description            |
| -------------- | --------- | ---------------------- |
| version_id     | UUID/Text | Version identifier     |
| journal_id     | UUID/Text | Associated journal     |
| version_number | Integer   | Version number         |
| title          | Text      | Historical title       |
| content        | Text      | Historical content     |
| modified_at    | DateTime  | Modification timestamp |
| modified_by    | UUID/Text | User identifier        |

---

## JournalTag

| Column         | Data Type | Description         |
| -------------- | --------- | ------------------- |
| journal_tag_id | UUID/Text | Junction identifier |
| journal_id     | UUID/Text | Journal identifier  |
| tag_id         | UUID/Text | Tag identifier      |

---

## JournalShare

| Column      | Data Type | Description          |
| ----------- | --------- | -------------------- |
| share_id    | UUID/Text | Share identifier     |
| journal_id  | UUID/Text | Shared entry         |
| share_token | Text      | Secure public token  |
| is_active   | Boolean   | Share status         |
| created_at  | DateTime  | Creation timestamp   |
| revoked_at  | DateTime  | Revocation timestamp |

---

## AnalyticsSnapshot

| Column          | Data Type | Description         |
| --------------- | --------- | ------------------- |
| snapshot_id     | UUID/Text | Snapshot identifier |
| user_id         | UUID/Text | User identifier     |
| total_entries   | Integer   | Entry count         |
| total_words     | Integer   | Total words         |
| current_streak  | Integer   | Active streak       |
| monthly_entries | Integer   | Monthly total       |
| snapshot_date   | Date      | Snapshot date       |

---

## ExportRequest

| Column        | Data Type | Description                            |
| ------------- | --------- | -------------------------------------- |
| export_id     | UUID/Text | Export identifier                      |
| user_id       | UUID/Text | Request owner                          |
| export_format | Text      | PDF or DOCX                            |
| export_status | Text      | Pending, Processing, Completed, Failed |
| requested_at  | DateTime  | Request timestamp                      |
| completed_at  | DateTime  | Completion timestamp                   |

---

## ExportFile

| Column       | Data Type | Description         |
| ------------ | --------- | ------------------- |
| file_id      | UUID/Text | File identifier     |
| export_id    | UUID/Text | Export request      |
| file_name    | Text      | Generated file name |
| download_url | Text      | Download location   |
| expires_at   | DateTime  | Download expiry     |
| created_at   | DateTime  | Creation timestamp  |

---

## Draft

| Column            | Data Type | Description             |
| ----------------- | --------- | ----------------------- |
| draft_id          | UUID/Text | Draft identifier        |
| user_id           | UUID/Text | Owner user              |
| journal_id        | UUID/Text | Related journal         |
| title             | Text      | Draft title             |
| content           | Text      | Draft content           |
| device_identifier | Text      | Client device reference |
| sync_status       | Text      | Pending, Synced         |
| saved_at          | DateTime  | Auto-save timestamp     |

---

## AuditLog

| Column           | Data Type | Description                           |
| ---------------- | --------- | ------------------------------------- |
| audit_id         | UUID/Text | Audit identifier                      |
| user_id          | UUID/Text | Actor                                 |
| entity_type      | Text      | Affected entity                       |
| entity_id        | UUID/Text | Record identifier                     |
| action_type      | Text      | Create, Update, Delete, Share, Export |
| action_timestamp | DateTime  | Event time                            |
| ip_address       | Text      | Request source                        |
| metadata         | Text      | Additional details                    |

---

# 4. Data Types

| Type      | Usage                            |
| --------- | -------------------------------- |
| UUID/Text | Primary identifiers              |
| Text      | Names, content, tokens, messages |
| Integer   | Counts and versions              |
| Boolean   | Flags and status indicators      |
| Date      | Calendar dates                   |
| DateTime  | Audit and activity timestamps    |

---

# 5. Constraints

## User

* Email must be unique.
* Email cannot be null.
* Password hash cannot be null.
* Account status must contain valid values only.

## JournalEntry

* User reference required.
* Title required.
* Content required.
* Entry date required.
* Version number must be positive.

## Tag

* Tag name unique per user.

## Category

* Category name unique per user.

## JournalShare

* Share token unique.
* Active share token required for public access.

## ExportRequest

* Export format limited to PDF and DOCX.

## AuditLog

* Action type mandatory.
* Timestamp mandatory.

---

# 6. Primary Keys

| Table                  | Primary Key     |
| ---------------------- | --------------- |
| User                   | user_id         |
| UserSession            | session_id      |
| PasswordResetToken     | reset_id        |
| EmailVerificationToken | verification_id |
| JournalEntry           | journal_id      |
| JournalEntryVersion    | version_id      |
| Category               | category_id     |
| Tag                    | tag_id          |
| JournalTag             | journal_tag_id  |
| JournalShare           | share_id        |
| AnalyticsSnapshot      | snapshot_id     |
| ExportRequest          | export_id       |
| ExportFile             | file_id         |
| Notification           | notification_id |
| Draft                  | draft_id        |
| AuditLog               | audit_id        |

---

# 7. Foreign Keys

| Child Table            | Foreign Key | Parent Table  |
| ---------------------- | ----------- | ------------- |
| UserSession            | user_id     | User          |
| PasswordResetToken     | user_id     | User          |
| EmailVerificationToken | user_id     | User          |
| Category               | user_id     | User          |
| Tag                    | user_id     | User          |
| JournalEntry           | user_id     | User          |
| JournalEntry           | category_id | Category      |
| JournalEntryVersion    | journal_id  | JournalEntry  |
| JournalTag             | journal_id  | JournalEntry  |
| JournalTag             | tag_id      | Tag           |
| JournalShare           | journal_id  | JournalEntry  |
| AnalyticsSnapshot      | user_id     | User          |
| ExportRequest          | user_id     | User          |
| ExportFile             | export_id   | ExportRequest |
| Notification           | user_id     | User          |
| Draft                  | user_id     | User          |
| Draft                  | journal_id  | JournalEntry  |
| AuditLog               | user_id     | User          |

---

# 8. Index Strategy

## Authentication

* User(email)
* User(account_status)
* UserSession(user_id)
* UserSession(expires_at)

## Journal Operations

* JournalEntry(user_id)
* JournalEntry(entry_date)
* JournalEntry(updated_at)
* JournalEntry(deleted_at)

## Search & Filtering

* JournalEntry(title)
* JournalEntry(entry_date)
* Tag(tag_name)
* JournalTag(journal_id)
* JournalTag(tag_id)

## Sharing

* JournalShare(share_token)
* JournalShare(is_active)

## Analytics

* AnalyticsSnapshot(user_id, snapshot_date)

## Exports

* ExportRequest(user_id)
* ExportRequest(export_status)

## Auditing

* AuditLog(user_id)
* AuditLog(action_timestamp)

---

# 9. Future Scalability

### Search Optimization

* Introduce SQLite FTS5 full-text indexing for title and content search.
* Support advanced ranking and keyword relevance.

### Analytics Expansion

* Add mood tracking analytics.
* Add sentiment analysis metrics.
* Support yearly trends.

### Collaboration Features

* Shared journals.
* Multiple contributors.
* Journal comments.

### Media Support

* Attach images, audio recordings, and documents.
* Add attachment metadata entity.

### Security Enhancements

* Multi-factor authentication.
* Device trust management.
* Security event monitoring.

### Export Expansion

* HTML export.
* Markdown export.
* Cloud storage integration.

### Offline Synchronization

* Multi-device draft synchronization.
* Conflict resolution framework.

---

# Entity Relationship Diagram (ERD)

```text
User
 ├── UserSession
 ├── PasswordResetToken
 ├── EmailVerificationToken
 ├── Category
 ├── Tag
 ├── JournalEntry
 │      ├── JournalEntryVersion
 │      ├── JournalShare
 │      └── Draft
 ├── AnalyticsSnapshot
 ├── ExportRequest
 │      └── ExportFile
 └── AuditLog

JournalEntry
 └── JournalTag
        └── Tag

Category
 └── JournalEntry
```

This design covers all KPI areas including registration, authentication, journal CRUD, rich-text storage, tagging, search/filtering, calendar navigation, sharing, analytics, exports, draft preservation, audit logging, performance support, and security controls.
