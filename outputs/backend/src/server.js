import app from './app.js';
import config from './config/environment.js';
import db from './config/db.js';
import logger from './config/logger.js';

let server;

// Verify Database connection sanity and start the HTTP server
db.get('SELECT 1;')
  .then(() => {
    logger.info('Database connection verified successfully.');
    // Check if any tables exist in the database
    return db.get("SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' LIMIT 1;");
  })
  .then((row) => {
    if (!row) {
      logger.info('No tables detected. Running automatic database schema initialization...');
      return import('./config/initDb.js').then(({ initDatabase }) => {
        return initDatabase(config.env === 'development');
      });
    } else {
      logger.info('Database tables verified.');
    }
  })
  .then(() => {
    server = app.listen(config.port, () => {
      logger.info(`Server is running on port ${config.port} in [${config.env}] mode`);
    });
  })
  .catch((error) => {
    logger.error('Fatal: Database initialization or verification failed: %o', error);
    process.exit(1);
  });

const exitHandler = () => {
  if (server) {
    server.close(() => {
      logger.info('HTTP server closed.');
      db.close()
        .then(() => {
          logger.info('Database connection closed.');
          process.exit(0);
        })
        .catch((err) => {
          logger.error('Error closing database: %o', err);
          process.exit(1);
        });
    });
  } else {
    process.exit(0);
  }
};

const unexpectedErrorHandler = (error) => {
  logger.error('Unexpected runtime error: %o', error);
  exitHandler();
};

process.on('uncaughtException', unexpectedErrorHandler);
process.on('unhandledRejection', unexpectedErrorHandler);

process.on('SIGTERM', () => {
  logger.info('SIGTERM signal received. Initiating graceful shutdown.');
  if (server) {
    server.close(() => {
      db.close().then(() => {
        process.exit(0);
      });
    });
  }
});

process.on('SIGINT', () => {
  logger.info('SIGINT signal received. Initiating graceful shutdown.');
  exitHandler();
});
