import 'package:dio/dio.dart';
import '../network/api_client.dart';
import '../models/models.dart';

class AnalyticsRepository {
  final ApiClient _apiClient;

  AnalyticsRepository(this._apiClient);

  Future<AnalyticsData> getAnalytics(List<JournalEntry> entries) async {
    try {
      final response = await _apiClient.dio.get('/analytics');
      final data = response.data as Map<String, dynamic>;

      final writingStreak = data['writingStreak'] as int;
      final totalEntries = data['totalEntries'] as int;
      final totalWords = data['totalWords'] as int;

      // Parse heatmapData array into Map<DateTime, int>
      final Map<DateTime, int> heatmap = {};
      if (data['heatmapData'] != null) {
        final rawHeatmap = data['heatmapData'] as List;
        for (final item in rawHeatmap) {
          final dateStr = item['date'] as String;
          final count = item['count'] as int;
          final date = DateTime.parse(dateStr);
          final normalizedDate = DateTime(date.year, date.month, date.day);
          heatmap[normalizedDate] = count;
        }
      }

      // Calculate categoryDistribution dynamically from entries list
      final Map<String, int> distribution = {};
      for (final entry in entries) {
        final category = entry.categoryId ?? 'Uncategorized';
        distribution[category] = (distribution[category] ?? 0) + 1;
      }

      // Calculate monthlyWords dynamically for the last 6 months (ending current month)
      final List<int> monthlyWordsList = [];
      final now = DateTime.now();
      for (int i = 5; i >= 0; i--) {
        final targetMonth = DateTime(now.year, now.month - i, 1);
        int sum = 0;
        for (final entry in entries) {
          if (entry.entryDate.year == targetMonth.year && entry.entryDate.month == targetMonth.month) {
            sum += entry.wordCount;
          }
        }
        monthlyWordsList.add(sum);
      }

      return AnalyticsData(
        writingStreak: writingStreak,
        totalEntries: totalEntries,
        totalWords: totalWords,
        heatmapData: heatmap,
        categoryDistribution: distribution,
        monthlyWords: monthlyWordsList,
      );
    } on DioException catch (e) {
      if (e.response != null && e.response!.data != null) {
        final errCode = e.response!.data['errorCode'];
        throw Exception(errCode ?? 'ANALYTICS_FAILED');
      }
      throw Exception('CONNECTION_ERROR');
    }
  }
}
