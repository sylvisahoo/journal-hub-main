# Implementation Plan - Backend Module 1: User Registration & Verification

Implement the backend for the **User Registration & Verification** module. This establishes the security foundations (hashing, Joi validation, rate limiting, and verification token workflow) supporting user onboarding.

## User Review Required

> [!IMPORTANT]
> - **Mock/Development Email Flow**: Nodemailer will attempt to send emails using SMTP credentials configured in `.env`. If SMTP connection fails or is not configured, the service will log the verification code to the console/logger to unblock QA testing and prevent registration requests from failing.
> - **Password Policy**: Password validation enforces a minimum of 8 characters. Weak password registration requests will return HTTP 400 with `WEAK_PASSWORD` error code.

---

## Proposed Changes

### [Backend Auth Layer]

All modifications are under [outputs/backend](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/backend).

#### [NEW] [userRepository.js](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/backend/src/repositories/userRepository.js)
Define User table queries:
- `findByEmail(email)`: find user by email.
- `findById(userId)`: find user by ID.
- `createUser(user)`: insert new User record.
- `updateUserStatus(userId, status)`: update user account status (`Pending`, `Verified`, `Disabled`).

#### [NEW] [verificationRepository.js](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/backend/src/repositories/verificationRepository.js)
Define EmailVerificationToken queries:
- `createToken(tokenRecord)`: insert verification token record.
- `findByToken(token)`: retrieve active verification token details.
- `markTokenAsUsed(verificationId)`: set verified_at timestamp on a token.

#### [NEW] [emailService.js](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/backend/src/services/emailService.js)
Nodemailer service:
- `sendVerificationEmail(email, token)`: generates verification email. Logs verification code to Winston console so QA can easily retrieve it during blackbox testing.

#### [NEW] [authService.js](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/backend/src/services/authService.js)
Core registration/verification orchestration:
- `registerUser({ fullName, email, password })`: hashes password with bcrypt, generates a UUID, inserts user as `Pending`, creates verification token, triggers verification email.
- `verifyEmail(token)`: retrieves token, validates expiration, marks token as used, updates user status to `Verified`.

#### [NEW] [authValidation.js](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/backend/src/validation/authValidation.js)
Input validation schema using Joi:
- Enforce valid fields, email format, and password min-length (8).
- Map Joi errors to specific API contract codes (`REQUIRED_FIELD_MISSING`, `INVALID_EMAIL`, `WEAK_PASSWORD`).

#### [NEW] [authController.js](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/backend/src/controllers/authController.js)
Controller handlers catching async errors:
- `register`: validates payload, calls `authService.registerUser`, responds with 201.
- `verifyEmail`: validates token payload, calls `authService.verifyEmail`, responds with 200.

#### [NEW] [authRoutes.js](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/backend/src/routes/authRoutes.js)
Auth router endpoints:
- Apply `authLimiter` middleware.
- Define `POST /register` -> `authController.register`
- Define `POST /verify-email` -> `authController.verifyEmail`

#### [MODIFY] [app.js](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/backend/src/app.js)
Mount the auth router:
- Import `authRoutes` and register under `app.use('/api/v1/auth', authRoutes)`.

---

## Verification Plan

### Automated Tests
- Create `outputs/backend/tests/auth.test.js` [NEW] containing unit and integration tests using Jest and Supertest.
- Test Scenarios:
  - Successful registration (201, Pending status, token generated).
  - Validation failures (400, `REQUIRED_FIELD_MISSING`, `INVALID_EMAIL`, `WEAK_PASSWORD`).
  - Duplicate registration (409, `DUPLICATE_EMAIL`).
  - Successful verification (200, status updated to Verified).
  - Failed verification - Invalid Token (400, `INVALID_TOKEN`).
  - Failed verification - Expired Token (410, `TOKEN_EXPIRED`).
- Run `npm test` inside `outputs/backend`.

### Manual Verification
- Start backend service (`npm start`).
- Send registration POST request using `curl` and inspect backend stdout logs to extract the generated verification token.
- Submit the verification token to `/api/v1/auth/verify-email` and confirm the user status in database changes to `Verified`.
