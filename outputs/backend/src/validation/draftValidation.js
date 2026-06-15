import Joi from 'joi';
import { ApiError } from '../middleware/errorHandler.js';

export const saveDraftSchema = Joi.object({
  draftId: Joi.string().trim().allow(null, '').optional(),
  journalId: Joi.string().trim().allow(null, '').optional(),
  title: Joi.string().trim().allow('').optional(),
  content: Joi.string().trim().allow('').optional(),
  deviceIdentifier: Joi.string().trim().optional()
});

export const validate = (schema) => (req, res, next) => {
  const { error, value } = schema.validate(req.body, { abortEarly: true });
  if (error) {
    return next(new ApiError(400, 'VALIDATION_FAILURE', error.message));
  }
  req.body = value;
  next();
};

export default {
  saveDraftSchema,
  validate
};
