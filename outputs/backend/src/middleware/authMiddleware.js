import jwt from 'jsonwebtoken';
import config from '../config/environment.js';
import { ApiError } from './errorHandler.js';
import sessionRepository from '../repositories/sessionRepository.js';

export const authMiddleware = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      throw new ApiError(401, 'UNAUTHORIZED', 'Access token is required');
    }

    const token = authHeader.split(' ')[1];
    
    // 1. Verify JWT signature and expiration
    let payload;
    try {
      payload = jwt.verify(token, config.jwt.secret);
    } catch (err) {
      if (err.name === 'TokenExpiredError') {
        throw new ApiError(401, 'TOKEN_EXPIRED', 'Access token has expired');
      }
      throw new ApiError(401, 'INVALID_TOKEN', 'Access token is invalid');
    }

    // 2. Check if session is active in database
    const session = await sessionRepository.findByToken(token);
    if (!session || !session.is_active) {
      throw new ApiError(401, 'INVALID_SESSION', 'Session is inactive or has been logged out');
    }

    // 3. Attach user and session to request
    req.user = {
      userId: payload.userId,
      email: payload.email,
      fullName: payload.fullName
    };
    req.session = session;

    next();
  } catch (error) {
    next(error);
  }
};

export default authMiddleware;
