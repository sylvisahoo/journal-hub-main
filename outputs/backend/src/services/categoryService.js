import { v4 as uuidv4 } from 'uuid';
import categoryRepository from '../repositories/categoryRepository.js';
import { ApiError } from '../middleware/errorHandler.js';

export const categoryService = {
  async createCategory(userId, categoryName) {
    const trimmedName = categoryName.trim();
    if (!trimmedName) {
      throw new ApiError(400, 'CATEGORY_NAME_REQUIRED', 'Category name cannot be empty');
    }

    const existing = await categoryRepository.findByNameAndUser(trimmedName, userId);
    if (existing) {
      throw new ApiError(409, 'DUPLICATE_CATEGORY', 'Category name already exists');
    }

    const categoryId = `c-${uuidv4()}`;
    return categoryRepository.create({ categoryId, userId, categoryName: trimmedName });
  },

  async getCategories(userId) {
    return categoryRepository.findByUser(userId);
  }
};

export default categoryService;
