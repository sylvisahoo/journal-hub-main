# Journal Hub Backend

Backend API for **Journal Hub** - Personal Journal & Diary Application. Built using Node.js v24.16.0, Express v5.2.1, and SQLite v3.52.0.

## Table of Contents
- [Architecture](#architecture)
- [Folder Structure](#folder-structure)
- [Prerequisites](#prerequisites)
- [Getting Started](#getting-started)
- [Environment Variables](#environment-variables)
- [Scripts](#scripts)
- [Testing](#testing)

---

## Architecture

This project adopts a clean, layered component architecture matching domain-driven design principles:

- **Express Layer (`app.js`, `server.js`)**: Configures application middleware, routing base configurations, and starts the HTTP server.
- **Config Layer (`src/config/`)**: Environment validation, database connectivity, and Winston logger setup.
- **Middleware Layer (`src/middleware/`)**: Authentication, rate limiters, input validation schemas, and centralized error handlers.
- **Component Layer (`src/components/`)**: Clean Separation of Concerns following:
  - Controllers: Handle HTTP requests and mapping.
  - Services: House core business logic.
  - Repositories: Direct access to SQLite database.

---

## Folder Structure

```text
outputs/backend/
├── src/
│   ├── config/
│   │   ├── db.js          # SQLite connection and setup
│   │   ├── logger.js      # Winston logger configuration
│   │   └── environment.js # Environment variables validation and config
│   ├── middleware/
│   │   ├── errorHandler.js# Centralized error handler
│   │   └── rateLimiter.js # Rate limiters
│   ├── components/        # Layered components (User, Auth, Journal, etc.)
│   ├── app.js             # Express application configuration
│   └── server.js          # Server entry point
├── tests/
│   └── sanity.test.js     # Health and Routing Integration Tests
├── .env.example           # Template env variables file
├── .env                   # Configuration file (ignored by git in production)
├── jest.config.js         # Jest configuration
└── package.json           # Project manifest
```

---

## Prerequisites

- **Node.js**: `v24.16.0`
- **NPM**: `v10+` (standard with Node.js v24)

---

## Getting Started

1. Navigate to the backend directory:
   ```bash
   cd outputs/backend
   ```

2. Install the dependencies:
   ```bash
   npm install
   ```

3. Create the `.env` file from the example:
   ```bash
   cp .env.example .env
   ```

4. Run the development server (automatically reloads using nodemon):
   ```bash
   npm run dev
   ```

5. Access the API:
   The base URL defaults to `http://localhost:5000/api/v1`.
   Hit the health check endpoint at `http://localhost:5000/api/v1/health`.

---

## Environment Variables

| Variable | Description | Default |
| --- | --- | --- |
| `PORT` | Listening port of the Express server | `5000` |
| `NODE_ENV` | Running mode environment (`development`, `production`, `test`) | `development` |
| `JWT_SECRET` | Secure key to sign JWT Access Tokens | *Required* |
| `JWT_REFRESH_SECRET` | Secure key to sign JWT Refresh Tokens | *Required* |
| `DATABASE_PATH` | Path location for the SQLite database file | `sqlite.db` |
| `EMAIL_HOST` | SMTP server host address | `smtp.mailtrap.io` |
| `EMAIL_PORT` | SMTP port | `2525` |
| `EMAIL_USER` | SMTP username credentials | - |
| `EMAIL_PASS` | SMTP password credentials | - |

---

## Scripts

- `npm start`: Starts the application in production mode.
- `npm run dev`: Starts the application in development mode with automatic restarts.
- `npm test`: Runs integration and unit test suites via Jest.

---

## Testing

Jest and Supertest are used for automated integration and unit testing.

Run all tests:
```bash
npm test
```
