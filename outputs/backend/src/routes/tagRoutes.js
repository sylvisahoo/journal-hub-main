import express from 'express';
import tagController from '../controllers/tagController.js';
import tagValidation from '../validation/tagValidation.js';
import authMiddleware from '../middleware/authMiddleware.js';

const router = express.Router();

// Apply auth middleware to all tag routes
router.use(authMiddleware);

router.post(
  '/',
  tagValidation.validate(tagValidation.createTagSchema),
  tagController.createTag
);

router.get('/', tagController.getTags);

export default router;
