import bcrypt from 'bcrypt';
import crypto from 'crypto';
import jwt from 'jsonwebtoken';
import { v4 as uuidv4 } from 'uuid';
import config from '../config/environment.js';
import userRepository from '../repositories/userRepository.js';
import verificationRepository from '../repositories/verificationRepository.js';
import sessionRepository from '../repositories/sessionRepository.js';
import passwordResetRepository from '../repositories/passwordResetRepository.js';
import auditRepository from '../repositories/auditRepository.js';
import emailService from './emailService.js';
import { ApiError } from '../middleware/errorHandler.js';

export const authService = {
  async registerUser({ fullName, email, password }, clientIp = null) {
    // 1. Check duplicate email
    const existingUser = await userRepository.findByEmail(email);
    if (existingUser) {
      throw new ApiError(409, 'DUPLICATE_EMAIL', 'Email address is already registered');
    }

    // 2. Hash password
    const passwordHash = await bcrypt.hash(password, 10);

    // 3. Create user record
    const userId = `u-${uuidv4()}`;
    const userRecord = {
      userId,
      fullName,
      email,
      passwordHash,
      accountStatus: 'Pending'
    };
    const user = await userRepository.createUser(userRecord);

    // 4. Set hardcoded verification token to '123456' for demo
    const verificationId = `v-${uuidv4()}`;
    const token = '123456';
    const expiresAt = new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString();

    await verificationRepository.createToken({
      verificationId,
      userId,
      token,
      expiresAt
    });

    // 5. Skip email delivery for demo purposes
    // await emailService.sendVerificationEmail(email, token);

    // Log audit for registration
    await auditRepository.log(userId, 'User', userId, 'Register', clientIp);

    return user;
  },

  async verifyEmail(token) {
    // 1. Retrieve verification record
    const tokenRecord = await verificationRepository.findByToken(token);
    if (!tokenRecord) {
      throw new ApiError(400, 'INVALID_TOKEN', 'Verification token is invalid');
    }

    // 2. Check expiration
    const expiresAt = new Date(tokenRecord.expires_at);
    if (expiresAt < new Date()) {
      throw new ApiError(410, 'TOKEN_EXPIRED', 'Verification token has expired');
    }

    // 3. Update status to Verified
    await userRepository.updateUserStatus(tokenRecord.user_id, 'Verified');

    // 4. Mark token as used
    await verificationRepository.markTokenAsUsed(tokenRecord.verification_id);

    return {
      status: 'SUCCESS',
      message: 'Email verified successfully'
    };
  },

  async loginUser({ email, password }, clientIp = null) {
    // 1. Fetch user by email
    const user = await userRepository.findByEmail(email);
    if (!user) {
      throw new ApiError(401, 'INVALID_CREDENTIALS', 'Invalid email or password');
    }

    // 2. Check password matches
    const isPasswordValid = await bcrypt.compare(password, user.password_hash);
    if (!isPasswordValid) {
      throw new ApiError(401, 'INVALID_CREDENTIALS', 'Invalid email or password');
    }

    // 3. Verify status
    if (user.account_status === 'Pending') {
      throw new ApiError(401, 'ACCOUNT_NOT_VERIFIED', 'Your account has not been verified yet');
    } else if (user.account_status === 'Disabled') {
      throw new ApiError(401, 'ACCOUNT_DISABLED', 'Your account has been disabled');
    }

    // 4. Generate JWT tokens
    const accessToken = jwt.sign(
      { userId: user.user_id, email: user.email, fullName: user.full_name },
      config.jwt.secret,
      { expiresIn: `${config.jwt.accessExpirationMinutes}m` }
    );
    const refreshToken = jwt.sign(
      { userId: user.user_id },
      config.jwt.refreshSecret,
      { expiresIn: `${config.jwt.refreshExpirationDays}d` }
    );

    const expiresAt = new Date(Date.now() + config.jwt.accessExpirationMinutes * 60 * 1000).toISOString();

    // 5. Save session
    const sessionId = `s-${uuidv4()}`;
    await sessionRepository.createSession({
      sessionId,
      userId: user.user_id,
      accessToken,
      refreshToken,
      expiresAt: new Date(Date.now() + config.jwt.refreshExpirationDays * 24 * 60 * 60 * 1000).toISOString()
    });

    // 6. Update user's last login timestamp
    await userRepository.updateLastLogin(user.user_id);

    // Log audit for login
    await auditRepository.log(user.user_id, 'User', user.user_id, 'Login', clientIp);

    return {
      accessToken,
      refreshToken,
      expiresAt
    };
  },

  async forgotPassword(email) {
    const user = await userRepository.findByEmail(email);
    if (!user) {
      throw new ApiError(400, 'INVALID_EMAIL', 'Email address is not registered');
    }

    // Generate numeric 6-digit token
    const token = Math.floor(100000 + Math.random() * 900000).toString();
    const expiresAt = new Date(Date.now() + 1 * 60 * 60 * 1000).toISOString(); // 1 hour expiration

    const resetId = `r-${uuidv4()}`;
    await passwordResetRepository.createResetToken({
      resetId,
      userId: user.user_id,
      token,
      expiresAt
    });

    await emailService.sendPasswordResetEmail(user.email, token);

    return {
      message: 'Password reset code has been sent to your email'
    };
  },

  async resetPassword(token, newPassword) {
    // 1. Find active reset token
    const resetTokenRecord = await passwordResetRepository.findByToken(token);
    if (!resetTokenRecord) {
      throw new ApiError(400, 'INVALID_TOKEN', 'Reset token is invalid');
    }

    // 2. Check expiration
    const expiresAt = new Date(resetTokenRecord.expires_at);
    if (expiresAt < new Date()) {
      throw new ApiError(410, 'TOKEN_EXPIRED', 'Reset token has expired');
    }

    // 3. Update password hash
    const passwordHash = await bcrypt.hash(newPassword, 10);
    await userRepository.updatePassword(resetTokenRecord.user_id, passwordHash);

    // 4. Mark token as used
    await passwordResetRepository.markTokenAsUsed(resetTokenRecord.reset_id);

    // 5. Invalidate all user sessions
    await sessionRepository.invalidateAllUserSessions(resetTokenRecord.user_id);

    return {
      message: 'Password has been reset successfully'
    };
  },

  async logoutUser(token) {
    const session = await sessionRepository.findByToken(token);
    if (!session) {
      throw new ApiError(401, 'INVALID_SESSION', 'Session is inactive or invalid');
    }
    await sessionRepository.invalidateSession(session.session_id);
    return {
      message: 'Logged out successfully'
    };
  }
};

export default authService;
