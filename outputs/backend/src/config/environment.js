import dotenv from 'dotenv';
import Joi from 'joi';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Load environment variables
dotenv.config({ path: path.resolve(__dirname, '../../.env') });

const envVarsSchema = Joi.object()
  .keys({
    NODE_ENV: Joi.string().valid('production', 'development', 'test').default('development'),
    PORT: Joi.number().default(5000),
    JWT_SECRET: Joi.string().required().description('JWT Access Token secret key is required'),
    JWT_REFRESH_SECRET: Joi.string().required().description('JWT Refresh Token secret key is required'),
    DATABASE_PATH: Joi.string().required().description('Database path is required'),
    EMAIL_HOST: Joi.string().description('SMTP host for sending verification emails'),
    EMAIL_PORT: Joi.number().description('SMTP port'),
    EMAIL_USER: Joi.string().description('SMTP username'),
    EMAIL_PASS: Joi.string().description('SMTP password')
  })
  .unknown();

const { value: envVars, error } = envVarsSchema.prefs({ errors: { label: 'key' } }).validate(process.env);

if (error) {
  throw new Error(`Config validation error: ${error.message}`);
}

export const config = {
  env: envVars.NODE_ENV,
  port: envVars.PORT,
  jwt: {
    secret: envVars.JWT_SECRET,
    refreshSecret: envVars.JWT_REFRESH_SECRET,
    accessExpirationMinutes: 15,
    refreshExpirationDays: 7
  },
  db: {
    path: envVars.DATABASE_PATH
  },
  email: {
    host: envVars.EMAIL_HOST,
    port: envVars.EMAIL_PORT,
    auth: {
      user: envVars.EMAIL_USER,
      pass: envVars.EMAIL_PASS
    }
  }
};
export default config;
