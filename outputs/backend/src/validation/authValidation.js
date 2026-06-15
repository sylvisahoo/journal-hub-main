import Joi from 'joi';
import { ApiError } from '../middleware/errorHandler.js';

export const registerSchema = Joi.object({
  fullName: Joi.string().trim().required().messages({
    'any.required': 'REQUIRED_FIELD_MISSING',
    'string.empty': 'REQUIRED_FIELD_MISSING'
  }),
  email: Joi.string().trim().lowercase().email().required().messages({
    'any.required': 'REQUIRED_FIELD_MISSING',
    'string.empty': 'REQUIRED_FIELD_MISSING',
    'string.email': 'INVALID_EMAIL'
  }),
  password: Joi.string().min(8).required().messages({
    'any.required': 'REQUIRED_FIELD_MISSING',
    'string.empty': 'REQUIRED_FIELD_MISSING',
    'string.min': 'WEAK_PASSWORD'
  })
});

export const verifyEmailSchema = Joi.object({
  verificationToken: Joi.string().trim().required().messages({
    'any.required': 'REQUIRED_FIELD_MISSING',
    'string.empty': 'REQUIRED_FIELD_MISSING'
  })
});

export const loginSchema = Joi.object({
  email: Joi.string().trim().lowercase().email().required().messages({
    'any.required': 'REQUIRED_FIELD_MISSING',
    'string.empty': 'REQUIRED_FIELD_MISSING',
    'string.email': 'INVALID_EMAIL'
  }),
  password: Joi.string().required().messages({
    'any.required': 'REQUIRED_FIELD_MISSING',
    'string.empty': 'REQUIRED_FIELD_MISSING'
  })
});

export const forgotPasswordSchema = Joi.object({
  email: Joi.string().trim().lowercase().email().required().messages({
    'any.required': 'REQUIRED_FIELD_MISSING',
    'string.empty': 'REQUIRED_FIELD_MISSING',
    'string.email': 'INVALID_EMAIL'
  })
});

export const resetPasswordSchema = Joi.object({
  resetToken: Joi.string().trim().required().messages({
    'any.required': 'REQUIRED_FIELD_MISSING',
    'string.empty': 'REQUIRED_FIELD_MISSING'
  }),
  newPassword: Joi.string().min(8).required().messages({
    'any.required': 'REQUIRED_FIELD_MISSING',
    'string.empty': 'REQUIRED_FIELD_MISSING',
    'string.min': 'WEAK_PASSWORD'
  })
});

export const validate = (schema) => (req, res, next) => {
  const { error, value } = schema.validate(req.body, { abortEarly: true });
  if (error) {
    const detail = error.details[0];
    const errorCode = detail.message; // Custom message is the error code
    let statusMsg = detail.message;

    if (errorCode === 'REQUIRED_FIELD_MISSING') {
      statusMsg = `${detail.path[0]} is required`;
    } else if (errorCode === 'INVALID_EMAIL') {
      statusMsg = 'Enter a valid email address';
    } else if (errorCode === 'WEAK_PASSWORD') {
      statusMsg = 'Password must be at least 8 characters long';
    } else {
      // Fallback Joi message
      return next(new ApiError(400, 'VALIDATION_FAILURE', error.message));
    }
    
    return next(new ApiError(400, errorCode, statusMsg));
  }
  req.body = value;
  next();
};

export default {
  registerSchema,
  verifyEmailSchema,
  loginSchema,
  forgotPasswordSchema,
  resetPasswordSchema,
  validate
};
