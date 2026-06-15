import sqlite3 from 'sqlite3';
import path from 'path';
import fs from 'fs';
import config from './environment.js';
import logger from './logger.js';

// Resolve database file path
const originalDbPath = path.resolve(config.db.path);
const dbDir = path.dirname(originalDbPath);
const dbPath = process.env.NODE_ENV === 'test'
  ? path.join(dbDir, 'journal_test.db')
  : originalDbPath;

// Create directory if it does not exist
if (!fs.existsSync(dbDir)) {
  fs.mkdirSync(dbDir, { recursive: true });
}

// Connect to SQLite
const dbInstance = new (sqlite3.verbose().Database)(dbPath, (err) => {
  if (err) {
    logger.error('SQLite connection error: %o', err);
    throw err;
  }
  logger.info(`Connected to SQLite database at: ${dbPath}`);
});

// Enable foreign keys
dbInstance.serialize(() => {
  dbInstance.run('PRAGMA foreign_keys = ON;', (err) => {
    if (err) {
      logger.error('Failed to enable foreign keys: %o', err);
    } else {
      logger.info('SQLite Foreign Key constraints enabled.');
    }
  });
});

// Promisified database operations wrapper
const db = {
  run(sql, params = []) {
    return new Promise((resolve, reject) => {
      dbInstance.run(sql, params, function (err) {
        if (err) {
          logger.error(`SQLite run query error: ${sql} | Error: %o`, err);
          return reject(err);
        }
        resolve({ lastID: this.lastID, changes: this.changes });
      });
    });
  },

  get(sql, params = []) {
    return new Promise((resolve, reject) => {
      dbInstance.get(sql, params, (err, row) => {
        if (err) {
          logger.error(`SQLite get query error: ${sql} | Error: %o`, err);
          return reject(err);
        }
        resolve(row);
      });
    });
  },

  all(sql, params = []) {
    return new Promise((resolve, reject) => {
      dbInstance.all(sql, params, (err, rows) => {
        if (err) {
          logger.error(`SQLite all query error: ${sql} | Error: %o`, err);
          return reject(err);
        }
        resolve(rows);
      });
    });
  },

  exec(sql) {
    return new Promise((resolve, reject) => {
      dbInstance.exec(sql, (err) => {
        if (err) {
          logger.error(`SQLite exec query error: ${sql} | Error: %o`, err);
          return reject(err);
        }
        resolve();
      });
    });
  },

  close() {
    return new Promise((resolve, reject) => {
      dbInstance.close((err) => {
        if (err) {
          logger.error('Failed to close SQLite connection: %o', err);
          return reject(err);
        }
        resolve();
      });
    });
  },

  instance: dbInstance
};

export default db;
export { db };
