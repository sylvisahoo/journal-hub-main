import categoryService from '../services/categoryService.js';

export const categoryController = {
  async createCategory(req, res, next) {
    try {
      const category = await categoryService.createCategory(req.user.userId, req.body.categoryName);
      res.status(201).json(category);
    } catch (err) {
      next(err);
    }
  },

  async getCategories(req, res, next) {
    try {
      const categories = await categoryService.getCategories(req.user.userId);
      res.status(200).json(categories);
    } catch (err) {
      next(err);
    }
  }
};

export default categoryController;
