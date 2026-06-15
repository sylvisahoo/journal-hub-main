import analyticsService from '../services/analyticsService.js';

export const analyticsController = {
  async getAnalytics(req, res, next) {
    try {
      const result = await analyticsService.getUserAnalytics(req.user.userId);
      res.status(200).json(result);
    } catch (err) {
      next(err);
    }
  }
};

export default analyticsController;
