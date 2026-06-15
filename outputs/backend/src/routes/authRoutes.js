import express from 'express';
import authController from '../controllers/authController.js';
import {
  registerSchema,
  verifyEmailSchema,
  loginSchema,
  forgotPasswordSchema,
  resetPasswordSchema,
  validate
} from '../validation/authValidation.js';
import { authLimiter } from '../middleware/rateLimiter.js';
import { authMiddleware } from '../middleware/authMiddleware.js';

const router = express.Router();

// Apply auth rate limiter to all auth routes
router.use(authLimiter);

// Registration Endpoint
router.post('/register', validate(registerSchema), authController.register);

// Verification Endpoint
router.post('/verify-email', validate(verifyEmailSchema), authController.verifyEmail);
router.get('/verify-email', authController.verifyEmailGet);

// Login Endpoint
router.post('/login', validate(loginSchema), authController.login);

// Forgot Password Endpoint
router.post('/forgot-password', validate(forgotPasswordSchema), authController.forgotPassword);

// Reset Password Endpoint
router.post('/reset-password', validate(resetPasswordSchema), authController.resetPassword);

// Logout Endpoint (Protected)
router.post('/logout', authMiddleware, authController.logout);

export default router;
