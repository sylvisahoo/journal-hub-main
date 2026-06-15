import journalRepository from '../repositories/journalRepository.js';

export const calendarService = {
  async getHighlightedDates(userId, month, year) {
    return journalRepository.findDatesByMonthAndYear(userId, month, year);
  }
};

export default calendarService;
