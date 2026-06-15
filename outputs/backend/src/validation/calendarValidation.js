import Joi from 'joi';
import { ApiError } from '../middleware/errorHandler.js';

export const getCalendarSchema = Joi.object({
  month: Joi.number().integer().min(1).max(12).required().messages({
    'any.required': 'INVALID_DATE_RANGE',
    'number.base': 'INVALID_DATE_RANGE',
    'number.min': 'INVALID_DATE_RANGE',
    'number.max': 'INVALID_DATE_RANGE'
  }),
  year: Joi.number().integer().min(1900).max(2100).required().messages({
    'any.required': 'INVALID_DATE_RANGE',
    'number.base': 'INVALID_DATE_RANGE',
    'number.min': 'INVALID_DATE_RANGE',
    'number.max': 'INVALID_DATE_RANGE'
  })
});

export const validateQuery = (schema) => (req, res, next) => {
  const { error, value } = schema.validate(req.query, { abortEarly: true });
  if (error) {
    const detail = error.details[0];
    const errorCode = detail.message;
    let statusMsg = detail.message;

    if (errorCode === 'INVALID_DATE_RANGE') {
      statusMsg = 'A valid month (1-12) and year are required';
    } else {
      return next(new ApiError(400, 'INVALID_DATE_RANGE', error.message));
    }
    return next(new ApiError(400, errorCode, statusMsg));
  }
  for (const key of Object.keys(req.query)) {
    delete req.query[key];
  }
  Object.assign(req.query, value);
  next();
};

export default {
  getCalendarSchema,
  validateQuery
};
