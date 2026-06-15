# Implementation Plan - Backend Module 2: Authentication & Session Management

Implement backend endpoints, validators, services, repositories, and testing for user authentication, session management, logout, and password recovery.

## Proposed Changes

### [Repositories]

#### [NEW] [sessionRepository.js](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/backend/src/repositories/sessionRepository.js)
Create database helper layer for active user sessions:
- `createSession(session)`: inserts a session record in `UserSession`.
- `findByToken(token)`: retrieves session where `access_token = ?`.
- `findByRefreshToken(token)`: retrieves session where `refresh_token = ?`.
- `invalidateSession(sessionId)`: sets `is_active = 0` for a specific session.
- `invalidateAllUserSessions(userId)`: sets `is_active = 0` for all user sessions (for password resets).

#### [NEW] [passwordResetRepository.js](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/backend/src/repositories/passwordResetRepository.js)
Create database helper layer for password reset tokens:
- `createResetToken(record)`: inserts a record into `PasswordResetToken`.
- `findByToken(token)`: retrieves active token where `token = ? AND used_at IS NULL`.
- `markTokenAsUsed(resetId)`: sets `used_at = CURRENT_TIMESTAMP` for the token.

#### [MODIFY] [userRepository.js](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/backend/src/repositories/userRepository.js)
Add password modification and last login methods:
- `updatePassword(userId, passwordHash)`: updates user password.
- `updateLastLogin(userId)`: updates `last_login_at = CURRENT_TIMESTAMP`.

---

### [Services]

#### [MODIFY] [emailService.js](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/backend/src/services/emailService.js)
Add password reset email dispatcher:
- `sendPasswordResetEmail(email, token)`: dispatches email via Nodemailer and logs the token in winston logs for local testing.

#### [MODIFY] [authService.js](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/backend/src/services/authService.js)
Add authentication business logic:
- `loginUser({ email, password })`:
  - Validates user credentials via bcrypt.
  - Verifies status is not `Pending` or `Disabled`.
  - Generates JWT Access Token (15 min) and Refresh Token (7 days).
  - Saves session to `UserSession`.
  - Updates user's `last_login_at`.
- `forgotPassword(email)`:
  - Generates a cryptographically secure 6-digit numeric reset token.
  - Saves reset token (expires in 1 hour).
  - Sends email with token.
- `resetPassword(token, newPassword)`:
  - Validates token presence and expiration.
  - Hashes new password.
  - Updates user password, marks reset token as used, and invalidates all active sessions for security.
- `logoutUser(token)`:
  - Invalidates the active session matching the token.

---

### [Controllers & Routes]

#### [MODIFY] [authValidation.js](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/backend/src/validation/authValidation.js)
Add Joi validation schemas:
- `loginSchema`: validates `email` and `password`.
- `forgotPasswordSchema`: validates `email`.
- `resetPasswordSchema`: validates `resetToken` and `newPassword`.

#### [MODIFY] [authController.js](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/backend/src/controllers/authController.js)
Implement handlers:
- `login(req, res)`: calls `authService.loginUser`.
- `forgotPassword(req, res)`: calls `authService.forgotPassword`.
- `resetPassword(req, res)`: calls `authService.resetPassword`.
- `logout(req, res)`: calls `authService.logoutUser`.

#### [NEW] [authMiddleware.js](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/backend/src/middleware/authMiddleware.js)
Add session token validation:
- Extracts token from `Authorization: Bearer <token>` header.
- Decodes/verifies JWT access token.
- Checks if the session is active in the database.
- Attaches authenticated user payload to `req.user`.

#### [MODIFY] [authRoutes.js](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/backend/src/routes/authRoutes.js)
Register endpoints:
- `POST /auth/login`
- `POST /auth/forgot-password`
- `POST /auth/reset-password`
- `POST /auth/logout` (protected with `authMiddleware`)

---

## Verification Plan

### Automated Tests
- Create a new integration test suite `tests/auth_module2.test.js` cover:
  - Login validation errors, invalid credentials, pending account rejection, disabled account rejection.
  - JWT token structure validation and session storage.
  - Password reset initiation, token generation, invalid token check, token expiration check, and re-login with new password.
  - Logout endpoint validation (verifies session is marked inactive, and subsequent protected calls fail).
- Run `npm test`.
