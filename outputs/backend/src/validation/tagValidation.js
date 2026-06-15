import Joi from 'joi';
import { ApiError } from '../middleware/errorHandler.js';

export const createTagSchema = Joi.object({
  tagName: Joi.string().trim().required().messages({
    'any.required': 'REQUIRED_FIELD_MISSING',
    'string.empty': 'REQUIRED_FIELD_MISSING'
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
    } else {
      return next(new ApiError(400, 'VALIDATION_FAILURE', error.message));
    }
    return next(new ApiError(400, errorCode, statusMsg));
  }
  req.body = value;
  next();
};

export default {
  createTagSchema,
  validate
};
