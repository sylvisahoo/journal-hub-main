import Joi from 'joi';
import { ApiError } from '../middleware/errorHandler.js';

export const requestExportSchema = Joi.object({
  format: Joi.string().trim().valid('PDF', 'DOCX', 'JSON', 'HTML').required()
});

export const validate = (schema) => (req, res, next) => {
  const { error, value } = schema.validate(req.body, { abortEarly: true });
  if (error) {
    return next(new ApiError(400, 'INVALID_EXPORT_FORMAT', 'Format must be PDF, DOCX, JSON, or HTML'));
  }
  req.body = value;
  next();
};

export default {
  requestExportSchema,
  validate
};
