import analyticsRepository from '../repositories/analyticsRepository.js';

export const analyticsService = {
  async getUserAnalytics(userId) {
    const stats = await analyticsRepository.getBasicStats(userId);
    const dates = await analyticsRepository.getDistinctEntryDates(userId);
    const monthlyActivity = await analyticsRepository.getMonthlyActivity(userId);
    const heatmapData = await analyticsRepository.getHeatmapData(userId);

    // Calculate writing streak: consecutive days ending on the most recent entry date
    let writingStreak = 0;
    if (dates.length > 0) {
      const parseDate = (dStr) => {
        const [y, m, d] = dStr.split('-').map(Number);
        return new Date(y, m - 1, d);
      };

      const start = parseDate(dates[0]);
      for (let i = 0; i < dates.length; i++) {
        const current = parseDate(dates[i]);
        const diffTime = Math.abs(start - current);
        const diffDays = Math.round(diffTime / (1000 * 60 * 60 * 24));
        
        if (diffDays === i) {
          writingStreak++;
        } else {
          break;
        }
      }
    }

    return {
      writingStreak,
      totalEntries: stats.totalEntries,
      totalWords: stats.totalWords,
      monthlyActivity,
      heatmapData
    };
  }
};

export default analyticsService;
