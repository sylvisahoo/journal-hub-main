import tagService from '../services/tagService.js';

export const tagController = {
  async createTag(req, res, next) {
    try {
      const tag = await tagService.createTag(req.user.userId, req.body.tagName);
      res.status(201).json(tag);
    } catch (err) {
      next(err);
    }
  },

  async getTags(req, res, next) {
    try {
      const tags = await tagService.getTags(req.user.userId);
      res.status(200).json(tags);
    } catch (err) {
      next(err);
    }
  }
};

export default tagController;
