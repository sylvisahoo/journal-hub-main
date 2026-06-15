import calendarService from '../services/calendarService.js';

export const calendarController = {
  async getCalendar(req, res, next) {
    try {
      const { month, year } = req.query;
      const highlightedDates = await calendarService.getHighlightedDates(
        req.user.userId,
        parseInt(month, 10),
        parseInt(year, 10)
      );
      res.status(200).json(highlightedDates);
    } catch (err) {
      next(err);
    }
  }
};

export default calendarController;
