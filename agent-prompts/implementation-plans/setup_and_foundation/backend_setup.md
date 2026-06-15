# Implementation Plan - Backend Environment Setup

Initialize the backend development environment for the **Journal Hub** application under [outputs/backend](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/backend). This setup establishes the foundations of a clean, layered component architecture, integrating Node.js, Express, and SQLite.

## User Review Required

> [!NOTE]
> The backend setup will use **ES Modules** (`"type": "module"`) in Node.js v24.16.0 for clean and modern imports. All code will strictly adhere to relative imports.
> 
> A SQLite database file will be initialized in the workspace, and the SQLite `PRAGMA foreign_keys = ON;` rule will be enforced on connection to guarantee relational integrity.

## Proposed Changes

### [Backend Setup]

We will create the backend structure under [outputs/backend](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/backend).

#### [NEW] [package.json](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/backend/package.json)
Configure the Node.js project. Include:
- Node.js engine constraint `v24.16.0`
- `"type": "module"` for ES Modules
- Core dependencies: `express` (v5.2.1), `sqlite3`, `jsonwebtoken`, `bcrypt`, `joi`, `helmet`, `cors`, `morgan`, `multer`, `nodemailer`, `uuid`, `winston`, `express-rate-limit`, `dotenv`
- Dev dependencies: `jest`, `supertest`, `nodemon`
- NPM scripts: `dev`, `start`, `test`

#### [NEW] [jest.config.js](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/backend/jest.config.js)
Jest configuration specifying testing environment, ES modules support (`transform: {}` or standard options), and test matching.

#### [NEW] [.env.example](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/backend/.env.example) and [.env](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/backend/.env)
Define system configuration parameters:
- `PORT` (e.g. 5000)
- `NODE_ENV` (development/production/test)
- `JWT_SECRET` and `JWT_REFRESH_SECRET`
- `DATABASE_PATH` (path to SQLite database)
- Email configuration (`EMAIL_HOST`, `EMAIL_PORT`, `EMAIL_USER`, `EMAIL_PASS`)

#### [NEW] [environment.js](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/backend/src/config/environment.js)
Config module using Joi to parse and validate required environment variables at runtime startup, preventing start if variables are invalid or missing.

#### [NEW] [logger.js](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/backend/src/config/logger.js)
Winston configuration. Outputs structured JSON log to stdout/files in production, formatted color logs in development.

#### [NEW] [db.js](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/backend/src/config/db.js)
Initialize connection to SQLite database, execute `PRAGMA foreign_keys = ON;`, and export utility database handler.

#### [NEW] [errorHandler.js](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/backend/src/middleware/errorHandler.js)
Centralized Express error handling middleware. Catch all unhandled exceptions and format the API response following the Standard Error Response Structure:
```json
{
  "errorCode": "INTERNAL_SERVER_ERROR / VALIDATION_ERROR / etc.",
  "message": "...",
  "timestamp": "2026-06-10T17:05:09Z",
  "requestId": "uuid-v4-string"
}
```

#### [NEW] [rateLimiter.js](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/backend/src/middleware/rateLimiter.js)
Configure standard rate limiter using `express-rate-limit` for generic API routes, and a more strict rate limiter for authentication routes.

#### [NEW] [app.js](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/backend/src/app.js)
Bootstrap the Express application:
- Load security middleware (`helmet`, `cors`, rate-limiting)
- Request loggers (`morgan` custom formats integrating Winston logs)
- Parse JSON body and URL encoded parameters
- Configure basic routes under `/api/v1` with a sanity/health check endpoint `/api/v1/health`
- Inject the centralized error handler

#### [NEW] [server.js](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/backend/src/server.js)
Application entry point. Validate configuration environment, verify database connection, and listen to the designated port.

#### [NEW] [sanity.test.js](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/backend/tests/sanity.test.js)
An integration test file to verify that the Express server bootstraps, environment configuration is valid, and the `/api/v1/health` endpoint responds correctly.

#### [NEW] [README.md](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/backend/README.md)
Detailed setup instructions, scripts, environment variables schema, and commands for starting and testing the application.

---

## Verification Plan

### Automated Tests
- Run `npm install` and verify package compilation.
- Run `npm test` to verify Jest bootstraps and runs the health/sanity checks successfully.
- Verify Jest test coverage configurations.

### Manual Verification
- Start the server locally via `npm run dev`.
- Hit the health check API endpoint `/api/v1/health` via `curl` to check standard HTTP response format, headers, and status code.
- Test missing required environment variables to verify start-up fails gracefully with clear Joi validation messages.
