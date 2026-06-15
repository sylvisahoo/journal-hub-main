import 'dart:async';
import '../models/models.dart';
import 'journal_repository.dart';
import 'analytics_repository.dart';
import '../network/api_client.dart';

class MockAuthRepository {
  final Map<String, String> _users = {
    'verified@example.com': 'Password123!',
    'pending@example.com': 'Password123!',
    'disabled@example.com': 'Password123!',
  };

  final Map<String, String> _statuses = {
    'verified@example.com': 'Verified',
    'pending@example.com': 'Pending',
    'disabled@example.com': 'Disabled',
  };

  final Map<String, String> _names = {
    'verified@example.com': 'Jane Doe',
    'pending@example.com': 'John Doe',
    'disabled@example.com': 'Block User',
  };

  Future<User> login(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 600)); // Simulate networking
    if (!_users.containsKey(email) || _users[email] != password) {
      throw Exception('INVALID_CREDENTIALS');
    }
    final status = _statuses[email]!;
    if (status == 'Pending') {
      throw Exception('ACCOUNT_NOT_VERIFIED');
    } else if (status == 'Disabled') {
      throw Exception('ACCOUNT_DISABLED');
    }
    return User(
      userId: email == 'verified@example.com' ? 'user-1' : 'user-3',
      fullName: _names[email]!,
      email: email,
      accountStatus: status,
    );
  }

  Future<User> register(String fullName, String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 800));
    if (_users.containsKey(email)) {
      throw Exception('DUPLICATE_EMAIL');
    }
    if (password.length < 8) {
      throw Exception('WEAK_PASSWORD');
    }
    _users[email] = password;
    _statuses[email] = 'Verified';
    _names[email] = fullName;

    return User(
      userId: 'user-new-${DateTime.now().millisecondsSinceEpoch}',
      fullName: fullName,
      email: email,
      accountStatus: 'Verified',
    );
  }

  Future<void> forgotPassword(String email) async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (!_users.containsKey(email)) {
      throw Exception('INVALID_EMAIL');
    }
  }

  Future<void> resetPassword(String token, String newPassword) async {
    await Future.delayed(const Duration(milliseconds: 600));
    if (token != '123456') {
      throw Exception('INVALID_TOKEN');
    }
  }
}

class MockJournalRepository extends JournalRepository {
  MockJournalRepository() : super(ApiClient());

  @override
  final List<Category> categories = [
    const Category(categoryId: 'cat-1', name: 'Personal'),
    const Category(categoryId: 'cat-2', name: 'Work'),
    const Category(categoryId: 'cat-3', name: 'Ideas'),
    const Category(categoryId: 'cat-4', name: 'Travel'),
  ];

  @override
  final List<Tag> tags = [
    const Tag(tagId: 'tag-1', name: 'grateful'),
    const Tag(tagId: 'tag-2', name: 'brainstorming'),
    const Tag(tagId: 'tag-3', name: 'weekend'),
    const Tag(tagId: 'tag-4', name: 'health'),
    const Tag(tagId: 'tag-5', name: 'reflections'),
  ];

  @override
  Future<void> loadMetadata() async {}

  @override
  Future<List<Category>> fetchCategories() async => categories;

  @override
  Future<List<Tag>> fetchTags() async => tags;

  @override
  Future<Category> createCategory(String name) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final newCat = Category(categoryId: 'cat-${DateTime.now().millisecondsSinceEpoch}', name: name);
    categories.add(newCat);
    return newCat;
  }

  Future<void> deleteCategory(String categoryId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    categories.removeWhere((c) => c.categoryId == categoryId);
  }

  Future<Tag> createTag(String name) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final newTag = Tag(tagId: 'tag-${DateTime.now().millisecondsSinceEpoch}', name: name);
    tags.add(newTag);
    return newTag;
  }

  Future<void> deleteTag(String tagId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    tags.removeWhere((t) => t.tagId == tagId);
  }

  final List<JournalEntry> _entries = [
    JournalEntry(
      journalId: 'j-1',
      userId: 'user-1',
      categoryId: 'cat-1',
      title: 'A beautiful weekend getaway',
      content: 'Spent the weekend camping by the lake. The air was fresh and crisp. We sat by the campfire, talking under the stars, feeling completely at peace with life.',
      entryDate: DateTime.now().subtract(const Duration(days: 1)),
      tagIds: const ['tag-1', 'tag-3'],
      wordCount: 34,
      isPrivate: true,
      versionNumber: 1,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      updatedAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    JournalEntry(
      journalId: 'j-2',
      userId: 'user-1',
      categoryId: 'cat-2',
      title: 'Stitch UI Screens Integration',
      content: 'Today I started structuring the Flutter UI screens. Configured GoRouter routes for the ShellRoute, established AppTheme variables, and connected screens using Riverpod state management. The layout looks modern and clean.',
      entryDate: DateTime.now(),
      tagIds: const ['tag-2'],
      wordCount: 42,
      isPrivate: false,
      versionNumber: 1,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    JournalEntry(
      journalId: 'j-3',
      userId: 'user-1',
      categoryId: 'cat-3',
      title: 'App Ideas: Digital Diary enhancements',
      content: 'Brainstormed some potential additions to the journal app: adding mood analytics using NLP, allowing secure end-to-end encryption of local caches, and calendar heatmaps visual styling.',
      entryDate: DateTime.now().subtract(const Duration(days: 3)),
      tagIds: const ['tag-2', 'tag-5'],
      wordCount: 29,
      isPrivate: true,
      versionNumber: 1,
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
      updatedAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
    JournalEntry(
      journalId: 'j-4',
      userId: 'user-1',
      categoryId: 'cat-1',
      title: 'Morning routine improvements',
      content: 'Started waking up at 6:00 AM. Stretched for 10 minutes, made green tea, and spent 15 minutes writing. I already feel much more energetic and focused for work.',
      entryDate: DateTime.now().subtract(const Duration(days: 4)),
      tagIds: const ['tag-1', 'tag-4'],
      wordCount: 35,
      isPrivate: true,
      versionNumber: 2,
      createdAt: DateTime.now().subtract(const Duration(days: 4)),
      updatedAt: DateTime.now().subtract(const Duration(days: 4)),
    )
  ];

  @override
  Future<List<JournalEntry>> getEntries({
    String? keyword,
    String? categoryId,
    String? tagId,
    DateTime? startDate,
    DateTime? endDate,
    int? page,
    int? limit,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    var filtered = List<JournalEntry>.from(_entries);
    if (keyword != null && keyword.isNotEmpty) {
      final kw = keyword.toLowerCase();
      filtered = filtered.where((e) => e.title.toLowerCase().contains(kw) || e.content.toLowerCase().contains(kw)).toList();
    }
    if (categoryId != null && categoryId.isNotEmpty) {
      filtered = filtered.where((e) => e.categoryId == categoryId).toList();
    }
    if (tagId != null && tagId.isNotEmpty) {
      filtered = filtered.where((e) => e.tagIds.contains(tagId)).toList();
    }
    if (startDate != null) {
      final start = DateTime(startDate.year, startDate.month, startDate.day);
      filtered = filtered.where((e) => e.entryDate.isAfter(start) || e.entryDate.isAtSameMomentAs(start)).toList();
    }
    if (endDate != null) {
      final end = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59, 999);
      filtered = filtered.where((e) => e.entryDate.isBefore(end) || e.entryDate.isAtSameMomentAs(end)).toList();
    }

    // Sort by entryDate descending
    filtered.sort((a, b) => b.entryDate.compareTo(a.entryDate));

    if (page != null && limit != null) {
      final startIndex = (page - 1) * limit;
      if (startIndex >= filtered.length) {
        return [];
      }
      final endIndex = startIndex + limit;
      return filtered.sublist(startIndex, endIndex > filtered.length ? filtered.length : endIndex);
    }

    return filtered;
  }

  @override
  Future<List<String>> getCalendarDates(int month, int year) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final dates = _entries.where((e) => e.entryDate.year == year && e.entryDate.month == month)
        .map((e) {
          final d = e.entryDate;
          return "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";
        })
        .toSet()
        .toList();
    dates.sort();
    return dates;
  }

  Future<JournalEntry> createEntry(JournalEntry entry) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final newEntry = entry.copyWith(
      journalId: 'j-${DateTime.now().millisecondsSinceEpoch}',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      versionNumber: 1,
    );
    _entries.add(newEntry);
    return newEntry;
  }

  Future<JournalEntry> updateEntry(JournalEntry entry) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final idx = _entries.indexWhere((e) => e.journalId == entry.journalId);
    if (idx == -1) throw Exception('ENTRY_NOT_FOUND');
    
    // Simulate conflict detection if versions mismatch
    if (_entries[idx].versionNumber != entry.versionNumber) {
      throw Exception('VERSION_CONFLICT');
    }

    final updated = entry.copyWith(
      versionNumber: entry.versionNumber + 1,
      updatedAt: DateTime.now(),
    );
    _entries[idx] = updated;
    return updated;
  }

  @override
  Future<void> deleteEntry(String journalId, {bool permanent = false}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _entries.removeWhere((e) => e.journalId == journalId);
  }

  Future<String> generateShareLink(String journalId) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final entry = _entries.firstWhere((e) => e.journalId == journalId);
    return 'http://localhost:5001/api/v1/share/token-secure-${entry.journalId}';
  }
}

class MockAnalyticsRepository extends AnalyticsRepository {
  MockAnalyticsRepository() : super(ApiClient());

  @override
  Future<AnalyticsData> getAnalytics(List<JournalEntry> entries) async {
    await Future.delayed(const Duration(milliseconds: 400));
    
    int totalWords = 0;
    final Map<DateTime, int> heatmap = {};
    final Map<String, int> distribution = {};

    for (final entry in entries) {
      totalWords += entry.wordCount;
      final dateKey = DateTime(entry.entryDate.year, entry.entryDate.month, entry.entryDate.day);
      heatmap[dateKey] = (heatmap[dateKey] ?? 0) + 1;
      
      final category = entry.categoryId ?? 'Uncategorized';
      distribution[category] = (distribution[category] ?? 0) + 1;
    }

    // Hardcode some monthly progress counts
    return AnalyticsData(
      writingStreak: 3,
      totalEntries: entries.length,
      totalWords: totalWords,
      heatmapData: heatmap,
      categoryDistribution: distribution,
      monthlyWords: const [120, 180, 240, 210, 310, 450],
    );
  }
}

class MockExportRepository {
  final List<ExportJob> _jobs = [];

  Future<List<ExportJob>> getExportJobs() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return List.from(_jobs);
  }

  Future<ExportJob> requestExport(String format) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final newJob = ExportJob(
      exportId: 'exp-${DateTime.now().millisecondsSinceEpoch}',
      format: format,
      status: 'Pending',
      requestedAt: DateTime.now(),
    );
    _jobs.add(newJob);

    // Simulate async processing
    _simulateExportProcessing(newJob.exportId);

    return newJob;
  }

  void _simulateExportProcessing(String id) async {
    await Future.delayed(const Duration(seconds: 4));
    final idx = _jobs.indexWhere((j) => j.exportId == id);
    if (idx != -1) {
      _jobs[idx] = _jobs[idx].copyWith(
        status: 'Processing',
      );
      
      await Future.delayed(const Duration(seconds: 4));
      final idxCompleted = _jobs.indexWhere((j) => j.exportId == id);
      if (idxCompleted != -1) {
        _jobs[idxCompleted] = _jobs[idxCompleted].copyWith(
          status: 'Completed',
          downloadUrl: 'http://localhost:5001/api/v1/export/downloads/$id.${_jobs[idxCompleted].format.toLowerCase()}',
        );
      }
    }
  }
}
