import Joi from 'joi';
import { ApiError } from '../middleware/errorHandler.js';

// Query param schema for list journals (GET /journals)
export const listJournalsQuerySchema = Joi.object({
  keyword:   Joi.string().trim().optional(),
  category:  Joi.string().trim().optional(),
  tag:       Joi.string().trim().optional(),
  startDate: Joi.date().iso().optional().messages({
    'date.base':   'INVALID_DATE',
    'date.format': 'INVALID_DATE'
  }),
  endDate:   Joi.date().iso().optional().messages({
    'date.base':   'INVALID_DATE',
    'date.format': 'INVALID_DATE'
  }),
  page:  Joi.number().integer().min(1).optional(),
  limit: Joi.number().integer().min(1).max(500).optional()
}).custom((value, helpers) => {
  // Cross-field: endDate must not be before startDate when both are supplied
  if (value.startDate && value.endDate && value.startDate > value.endDate) {
    return helpers.error('any.invalid');
  }
  return value;
}).messages({
  'any.invalid': 'INVALID_FILTER'
});

export const createJournalSchema = Joi.object({
  title: Joi.string().trim().required().messages({
    'any.required': 'REQUIRED_FIELD_MISSING',
    'string.empty': 'REQUIRED_FIELD_MISSING'
  }),
  content: Joi.string().trim().required().messages({
    'any.required': 'CONTENT_REQUIRED',
    'string.empty': 'CONTENT_REQUIRED'
  }),
  entryDate: Joi.date().iso().required().messages({
    'any.required': 'REQUIRED_FIELD_MISSING',
    'date.base': 'INVALID_DATE',
    'date.format': 'INVALID_DATE'
  }),
  categoryId: Joi.string().trim().allow(null, '').optional(),
  tags: Joi.array().items(Joi.string().trim()).optional(),
  isPrivate: Joi.boolean().optional()
});

export const updateJournalSchema = Joi.object({
  title: Joi.string().trim().optional(),
  content: Joi.string().trim().optional().messages({
    'string.empty': 'CONTENT_REQUIRED'
  }),
  entryDate: Joi.date().iso().optional().messages({
    'date.base': 'INVALID_DATE',
    'date.format': 'INVALID_DATE'
  }),
  categoryId: Joi.string().trim().allow(null, '').optional(),
  tags: Joi.array().items(Joi.string().trim()).optional(),
  isPrivate: Joi.boolean().optional(),
  versionNumber: Joi.number().integer().required().messages({
    'any.required': 'VERSION_REQUIRED',
    'number.base': 'VERSION_REQUIRED'
  })
});

export const validate = (schema) => (req, res, next) => {
  const { error, value } = schema.validate(req.body, { abortEarly: true });
  if (error) {
    const detail = error.details[0];
    const errorCode = detail.message;
    let statusMsg = detail.message;

    if (errorCode === 'REQUIRED_FIELD_MISSING') {
      statusMsg = `${detail.path[0]} is required`;
    } else if (errorCode === 'CONTENT_REQUIRED') {
      statusMsg = 'Journal content cannot be empty';
    } else if (errorCode === 'INVALID_DATE') {
      statusMsg = 'A valid ISO date is required';
    } else if (errorCode === 'VERSION_REQUIRED') {
      statusMsg = 'Version number is required for updates';
    } else {
      return next(new ApiError(400, 'VALIDATION_FAILURE', error.message));
    }
    return next(new ApiError(400, errorCode, statusMsg));
  }
  req.body = value;
  next();
};

// Query validation middleware (used for GET /journals query params)
export const validateQuery = (schema) => (req, res, next) => {
  const { error, value } = schema.validate(req.query, { abortEarly: true });
  if (error) {
    const detail = error.details[0];
    const errorCode = detail.message;
    let statusMsg;
    if (errorCode === 'INVALID_FILTER') {
      statusMsg = 'startDate must be before endDate';
    } else if (errorCode === 'INVALID_DATE') {
      statusMsg = 'A valid ISO date is required for startDate and endDate';
    } else {
      statusMsg = error.message;
    }
    return next(new ApiError(400, errorCode === 'INVALID_FILTER' ? 'INVALID_FILTER' : 'INVALID_DATE', statusMsg));
  }
  // Replace raw query params with coerced Joi values
  Object.keys(req.query).forEach((k) => delete req.query[k]);
  Object.assign(req.query, value);
  next();
};

export default {
  createJournalSchema,
  updateJournalSchema,
  listJournalsQuerySchema,
  validate,
  validateQuery
};
