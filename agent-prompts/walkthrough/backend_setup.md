# Walkthrough - Backend Environment Setup

Successfully completed **Section 1.3 Development Environment Setup (Backend Setup)** for the **Journal Hub** application under [outputs/backend](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/backend).

## Changes Made

### 1. Repository Setup & package.json
Created the base folder structure and initialized `package.json` with constraints:
- Node.js version engine requirement: `v24.16.0` (compatible with current runtime `v25.6.1`)
- Enabled ES Modules (`"type": "module"`)
- Installed core dependencies: `express` (v5.0.1), `sqlite3`, `jsonwebtoken`, `bcrypt`, `joi`, `helmet`, `cors`, `morgan`, `multer`, `nodemailer`, `uuid`, `winston`, `express-rate-limit`, `dotenv`
- Installed dev dependencies: `jest`, `supertest`, `nodemon`

### 2. Configurations & Environment Validation
- Created [.env.example](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/backend/.env.example) and [.env](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/backend/.env). Modified default port configuration to `5001` to prevent conflicts with macOS AirPlay receiver (which binds to port 5000).
- Implemented environment validation in [environment.js](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/backend/src/config/environment.js) using Joi to parse and validate required configuration values on start.
- Configured structured console logging using Winston in [logger.js](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/backend/src/config/logger.js).
- Configured SQLite database connection wrapper in [db.js](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/backend/src/config/db.js) with Promisified queries and enforced foreign keys (`PRAGMA foreign_keys = ON;`).

### 3. Middleware & Security Setup
- Configured rate limiters in [rateLimiter.js](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/backend/src/middleware/rateLimiter.js) (global limits and strict auth limits).
- Implemented centralized error handling in [errorHandler.js](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/backend/src/middleware/errorHandler.js) using a custom `ApiError` class, formatting responses according to the Standard Error Response Structure:
  ```json
  {
    "errorCode": "...",
    "message": "...",
    "timestamp": "...",
    "requestId": "..."
  }
  ```

### 4. Server Bootstrapping
- Created [app.js](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/backend/src/app.js) to initialize Express, security headers (`helmet`), CORS (`cors`), body parsers, Winston request logging (`morgan`), global rate limiting, health check route `/api/v1/health`, fallback 404, and injected error handler middleware.
- Created [server.js](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/backend/src/server.js) to verify database connection connection integrity first, start the HTTP listener on port 5001, and register graceful shutdown handlers for process `SIGINT`/`SIGTERM`.

### 5. Documentation
- Created [README.md](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/backend/README.md) containing steps to install, configure, run, and test the application.

---

## Verification Results

### Automated Integration Tests
Executed integration test suite using Jest and Supertest in [sanity.test.js](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/backend/tests/sanity.test.js). All tests passed:
```text
info: Connected to SQLite database at: /Users/neo/Desktop/Vibe Coding Training/vibe_projects/journal-hub/outputs/backend/data/journal.db
info: SQLite Foreign Key constraints enabled.
info: GET /api/v1/health 200 100 - 5.698 ms
info: GET /api/v1/undefined-route-check 404 156 - 0.936 ms
PASS tests/sanity.test.js
  Sanity & Configuration Tests
    GET /api/v1/health
      ✓ should return 200 OK with the health check details (47 ms)
    GET /api/v1/undefined-route-check
      ✓ should return 404 NOT_FOUND and match the standard error response contract (7 ms)
```

### Manual Verification
1. Bootstrapped dev server using `npm run dev` (running on port `5001`).
2. Piped a curl request to health check: `curl -i http://localhost:5001/api/v1/health`
   ```http
   HTTP/1.1 200 OK
   ...
   RateLimit-Limit: 100
   RateLimit-Remaining: 99
   RateLimit-Reset: 900
   Content-Type: application/json; charset=utf-8
   Content-Length: 100

   {"status":"OK","timestamp":"2026-06-10T11:45:55.377Z","message":"Journal Hub API service is active"}
   ```
3. Piped a curl request to a non-existent route: `curl -i http://localhost:5001/api/v1/non-existent-route`
   ```http
   HTTP/1.1 404 Not Found
   ...
   Content-Type: application/json; charset=utf-8
   Content-Length: 1407

   {"errorCode":"NOT_FOUND","message":"Requested resource not found","timestamp":"2026-06-10T11:46:00.094Z","requestId":"f666ac24-df0b-4032-b6d7-a8766ff03441","stack":"..."}
   ```
   *Response conforms exactly to standard error response structure.*
