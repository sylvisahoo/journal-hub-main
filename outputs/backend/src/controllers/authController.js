import authService from '../services/authService.js';

export const authController = {
  async register(req, res, next) {
    try {
      const { fullName, email, password } = req.body;
      const clientIp = req.ip || req.headers['x-forwarded-for'] || req.socket.remoteAddress;
      const user = await authService.registerUser({ fullName, email, password }, clientIp);
      res.status(201).json({
        userId: user.user_id,
        accountStatus: user.account_status,
        message: 'Account created successfully. Please check your email to verify.'
      });
    } catch (error) {
      next(error);
    }
  },

  async verifyEmail(req, res, next) {
    try {
      const { verificationToken } = req.body;
      const result = await authService.verifyEmail(verificationToken);
      res.status(200).json(result);
    } catch (error) {
      next(error);
    }
  },

  async verifyEmailGet(req, res, next) {
    try {
      const { token } = req.query;
      if (!token || !token.trim()) {
        return res.status(400).send(`
          <html>
            <head>
              <title>Verification Failed</title>
              <style>
                body { font-family: sans-serif; text-align: center; padding: 50px; background-color: #f7f7f9; }
                .card { background: white; padding: 40px; border-radius: 8px; display: inline-block; box-shadow: 0 4px 6px rgba(0,0,0,0.1); }
                h1 { color: #d9534f; }
              </style>
            </head>
            <body>
              <div class="card">
                <h1>Verification Failed</h1>
                <p>Verification token is missing.</p>
              </div>
            </body>
          </html>
        `);
      }
      try {
        await authService.verifyEmail(token.trim());
        return res.status(200).send(`
          <html>
            <head>
              <title>Verification Successful</title>
              <style>
                body { font-family: sans-serif; text-align: center; padding: 50px; background-color: #f7f7f9; }
                .card { background: white; padding: 40px; border-radius: 8px; display: inline-block; box-shadow: 0 4px 6px rgba(0,0,0,0.1); }
                h1 { color: #5cb85c; }
              </style>
            </head>
            <body>
              <div class="card">
                <h1>Verification Successful!</h1>
                <p>Your email has been verified successfully. You can now log in to the application.</p>
              </div>
            </body>
          </html>
        `);
      } catch (error) {
        const message = error.message || 'Verification token is invalid or expired';
        return res.status(error.statusCode || 400).send(`
          <html>
            <head>
              <title>Verification Failed</title>
              <style>
                body { font-family: sans-serif; text-align: center; padding: 50px; background-color: #f7f7f9; }
                .card { background: white; padding: 40px; border-radius: 8px; display: inline-block; box-shadow: 0 4px 6px rgba(0,0,0,0.1); }
                h1 { color: #d9534f; }
              </style>
            </head>
            <body>
              <div class="card">
                <h1>Verification Failed</h1>
                <p>${message}</p>
              </div>
            </body>
          </html>
        `);
      }
    } catch (error) {
      next(error);
    }
  },

  async login(req, res, next) {
    try {
      const { email, password } = req.body;
      const clientIp = req.ip || req.headers['x-forwarded-for'] || req.socket.remoteAddress;
      const result = await authService.loginUser({ email, password }, clientIp);
      res.status(200).json(result);
    } catch (error) {
      next(error);
    }
  },

  async forgotPassword(req, res, next) {
    try {
      const { email } = req.body;
      const result = await authService.forgotPassword(email);
      res.status(200).json(result);
    } catch (error) {
      next(error);
    }
  },

  async resetPassword(req, res, next) {
    try {
      const { resetToken, newPassword } = req.body;
      const result = await authService.resetPassword(resetToken, newPassword);
      res.status(200).json(result);
    } catch (error) {
      next(error);
    }
  },

  async logout(req, res, next) {
    try {
      const authHeader = req.headers.authorization;
      const token = authHeader.split(' ')[1];
      const result = await authService.logoutUser(token);
      res.status(200).json(result);
    } catch (error) {
      next(error);
    }
  }
};

export default authController;
