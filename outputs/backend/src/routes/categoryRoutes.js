import express from 'express';
import categoryController from '../controllers/categoryController.js';
import categoryValidation from '../validation/categoryValidation.js';
import authMiddleware from '../middleware/authMiddleware.js';

const router = express.Router();

// Apply auth middleware to all category routes
router.use(authMiddleware);

router.post(
  '/',
  categoryValidation.validate(categoryValidation.createCategorySchema),
  categoryController.createCategory
);

router.get('/', categoryController.getCategories);

export default router;
