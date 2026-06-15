import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import db from './db.js';
import logger from './logger.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

export const initDatabase = async (seed = false) => {
  try {
    logger.info('Initializing database schema...');

    if (process.env.NODE_ENV === 'test') {
      logger.info('Test environment detected. Dropping existing tables to apply latest schema...');
      await db.exec(`
        PRAGMA foreign_keys = OFF;
        DROP TABLE IF EXISTS AuditLog;
        DROP TABLE IF EXISTS Draft;
        DROP TABLE IF EXISTS Notification;
        DROP TABLE IF EXISTS ExportFile;
        DROP TABLE IF EXISTS ExportRequest;
        DROP TABLE IF EXISTS AnalyticsSnapshot;
        DROP TABLE IF EXISTS JournalShare;
        DROP TABLE IF EXISTS JournalTag;
        DROP TABLE IF EXISTS JournalEntryVersion;
        DROP TABLE IF EXISTS JournalEntry;
        DROP TABLE IF EXISTS Tag;
        DROP TABLE IF EXISTS Category;
        DROP TABLE IF EXISTS EmailVerificationToken;
        DROP TABLE IF EXISTS PasswordResetToken;
        DROP TABLE IF EXISTS UserSession;
        DROP TABLE IF EXISTS User;
        PRAGMA foreign_keys = ON;
      `);
    }

    // Load schema.sql and execute batch
    const schemaPath = path.resolve(__dirname, 'schema.sql');
    const schemaSql = fs.readFileSync(schemaPath, 'utf8');
    await db.exec(schemaSql);
    logger.info('Database schema initialized successfully.');

    // Load seeds.sql if requested
    if (seed) {
      logger.info('Seeding mock database records...');
      const seedsPath = path.resolve(__dirname, 'seeds.sql');
      const seedsSql = fs.readFileSync(seedsPath, 'utf8');
      await db.exec(seedsSql);
      logger.info('Database seeding completed successfully.');
    }
  } catch (error) {
    logger.error('Error during database initialization: %o', error);
    throw error;
  }
};

// Check if run directly from command line (e.g. node initDb.js --seed)
const runAsScript = process.argv[1] && (process.argv[1] === __filename || process.argv[1].endsWith('initDb.js'));

if (runAsScript) {
  const seed = process.argv.includes('--seed') || process.argv.includes('-s');
  initDatabase(seed)
    .then(() => {
      logger.info('Database initialization script finished successfully.');
      return db.close();
    })
    .then(() => {
      process.exit(0);
    })
    .catch((err) => {
      logger.error('Database initialization script failed: %o', err);
      process.exit(1);
    });
}

export default initDatabase;
