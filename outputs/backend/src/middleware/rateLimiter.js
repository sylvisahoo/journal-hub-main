import { rateLimit } from 'express-rate-limit';
import { ApiError } from './errorHandler.js';

export const globalLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // Limit each IP to 100 requests per `window`
  standardHeaders: true, // Return rate limit info in the `RateLimit-*` headers
  legacyHeaders: false, // Disable the `X-RateLimit-*` headers
  handler: (req, res, next) => {
    next(new ApiError(429, 'RATE_LIMIT_EXCEEDED', 'Too many requests, please try again later.'));
  }
});

export const authLimiter = rateLimit({
  windowMs: 60 * 60 * 1000, // 1 hour
  max: 20, // Limit each IP to 20 requests per `window` for auth endpoints
  standardHeaders: true,
  legacyHeaders: false,
  handler: (req, res, next) => {
    next(new ApiError(429, 'AUTH_RATE_LIMIT_EXCEEDED', 'Too many authentication attempts, please try again after an hour.'));
  }
});

export default { globalLimiter, authLimiter };
