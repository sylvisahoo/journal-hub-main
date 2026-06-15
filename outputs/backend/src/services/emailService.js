import nodemailer from 'nodemailer';
import config from '../config/environment.js';
import logger from '../config/logger.js';

class EmailService {
  constructor() {
    // Initialize transporter only if configuration exists
    if (config.email.host && config.email.auth.user) {
      this.transporter = nodemailer.createTransport({
        host: config.email.host,
        port: config.email.port || 587,
        auth: {
          user: config.email.auth.user,
          pass: config.email.auth.pass
        }
      });
      logger.info('Nodemailer transporter initialized with SMTP configuration.');
    } else {
      logger.warn('SMTP configuration missing. EmailService will default to logging emails/tokens in console.');
    }
  }

  async sendVerificationEmail(email, token) {
    const verificationUrl = `http://localhost:${config.port || 5001}/api/v1/auth/verify-email?token=${token}`;
    const mailOptions = {
      from: '"Journal Hub" <no-reply@journalhub.com>',
      to: email,
      subject: 'Verify your Journal Hub Account',
      text: `Welcome to Journal Hub! Please verify your account by using the following token: ${token} or visiting: ${verificationUrl}`,
      html: `
        <h3>Welcome to Journal Hub!</h3>
        <p>Please click the link below to verify your email address:</p>
        <a href="${verificationUrl}" target="_blank">Verify Email Address</a>
        <br/><br/>
        <p>Or use the verification token directly: <strong>${token}</strong></p>
      `
    };

    logger.info(`[Email Verification Log] Destination: ${email} | Verification Token: ${token}`);

    if (this.transporter) {
      try {
        await this.transporter.sendMail(mailOptions);
        logger.info(`Verification email sent successfully to ${email}`);
      } catch (error) {
        logger.error(`Failed to send verification email to ${email} via SMTP: %o`, error);
        // Do not throw error here, so registration flow does not break when SMTP fails in test/dev
      }
    }
  }

  async sendPasswordResetEmail(email, token) {
    const mailOptions = {
      from: '"Journal Hub" <no-reply@journalhub.com>',
      to: email,
      subject: 'Reset your Journal Hub Password',
      text: `You requested a password reset. Please use the following token to reset your password: ${token}`,
      html: `
        <h3>Password Reset Request</h3>
        <p>Please use the following 6-digit token to reset your password:</p>
        <h2><strong>${token}</strong></h2>
      `
    };

    logger.info(`[Password Reset Log] Destination: ${email} | Reset Token: ${token}`);

    if (this.transporter) {
      try {
        await this.transporter.sendMail(mailOptions);
        logger.info(`Password reset email sent successfully to ${email}`);
      } catch (error) {
        logger.error(`Failed to send password reset email to ${email} via SMTP: %o`, error);
      }
    }
  }
}

export const emailService = new EmailService();
export default emailService;
