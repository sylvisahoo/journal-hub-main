import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:state_notifier/state_notifier.dart';
import '../models/models.dart';
import '../repositories/mock_repositories.dart';
import '../network/api_client.dart';
import '../repositories/auth_repository.dart';
import '../repositories/draft_repository.dart';
import '../repositories/journal_repository.dart';
import '../repositories/analytics_repository.dart';
import '../repositories/export_repository.dart';
import '../../config/router.dart';

// 1. Repository Providers
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AuthRepository(apiClient);
});

final draftRepositoryProvider = Provider<DraftRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return DraftRepository(apiClient);
});

final journalRepositoryProvider = Provider<JournalRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return JournalRepository(apiClient);
});

final analyticsRepositoryProvider = Provider<AnalyticsRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AnalyticsRepository(apiClient);
});

final exportRepositoryProvider = Provider<ExportRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ExportRepository(apiClient);
});

// 2. Auth State Provider
class AuthNotifier extends StateNotifier<AsyncValue<User?>> {
  final AuthRepository _repo;
  AuthNotifier(this._repo) : super(const AsyncValue.loading()) {
    _init();
    ApiClient.onUnauthorizedGlobal = () {
      clearSessionOnExpiry();
      goRouter.go('/login');
    };
  }

  void clearSessionOnExpiry() {
    state = const AsyncValue.data(null);
  }

  Future<void> _init() async {
    try {
      final user = await _repo.getCurrentUser();
      state = AsyncValue.data(user);
    } catch (e, stack) {
      state = AsyncValue.data(null);
    }
  }

  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final user = await _repo.login(email, password);
      state = AsyncValue.data(user);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<User> register(String fullName, String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final user = await _repo.register(fullName, email, password);
      state = const AsyncValue.data(null);
      return user;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  Future<void> forgotPassword(String email) async {
    state = const AsyncValue.loading();
    try {
      await _repo.forgotPassword(email);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> logout() async {
    state = const AsyncValue.loading();
    try {
      await _repo.logout();
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  void clearError() {
    state = AsyncValue.data(state.value);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AsyncValue<User?>>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return AuthNotifier(repo);
});

// 3. Categories & Tags Providers (Loaded from repository)
final categoriesProvider = Provider<List<Category>>((ref) {
  final repo = ref.watch(journalRepositoryProvider);
  return List.from(repo.categories);
});

final tagsProvider = Provider<List<Tag>>((ref) {
  final repo = ref.watch(journalRepositoryProvider);
  return List.from(repo.tags);
});

// 4. Journals State Notifier
// 4. Journals State Notifier
final allEntriesProvider = FutureProvider<List<JournalEntry>>((ref) async {
  final repo = ref.watch(journalRepositoryProvider);
  await repo.loadMetadata();
  return repo.getEntries();
});

final recentEntriesProvider = Provider<AsyncValue<List<JournalEntry>>>((ref) {
  final allEntriesState = ref.watch(allEntriesProvider);
  return allEntriesState.when(
    loading: () => const AsyncValue.loading(),
    error: (err, stack) => AsyncValue.error(err, stack),
    data: (entries) => AsyncValue.data(entries.take(3).toList()),
  );
});

class JournalsNotifier extends StateNotifier<AsyncValue<List<JournalEntry>>> {
  final JournalRepository _repo;
  final Ref _ref;
  JournalsNotifier(this._repo, this._ref) : super(const AsyncValue.loading()) {
    loadEntries();
  }

  Future<void> loadEntries() async {
    state = const AsyncValue.loading();
    try {
      await _repo.loadMetadata();
      final query = _ref.read(searchQueryProvider);
      final catId = _ref.read(selectedCategoryFilterProvider);
      final tagId = _ref.read(selectedTagFilterProvider);
      final dateRange = _ref.read(selectedDateRangeFilterProvider);

      final entries = await _repo.getEntries(
        keyword: query.isNotEmpty ? query : null,
        categoryId: catId,
        tagId: tagId,
        startDate: dateRange?.start,
        endDate: dateRange?.end,
      );
      state = AsyncValue.data(entries);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addEntry({
    required String title,
    required String content,
    required DateTime entryDate,
    String? categoryId,
    required List<String> tagIds,
    required bool isPrivate,
  }) async {
    final entry = JournalEntry(
      journalId: '',
      userId: 'user-1',
      categoryId: categoryId,
      title: title,
      content: content,
      entryDate: entryDate,
      tagIds: tagIds,
      wordCount: content.trim().split(RegExp(r'\s+')).length,
      isPrivate: isPrivate,
      versionNumber: 1,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      await _repo.createEntry(entry);
      _ref.invalidate(allEntriesProvider);
      await loadEntries();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  Future<void> updateEntry(JournalEntry entry) async {
    try {
      await _repo.updateEntry(entry);
      _ref.invalidate(allEntriesProvider);
      await loadEntries();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  Future<void> deleteEntry(String journalId) async {
    try {
      await _repo.deleteEntry(journalId);
      _ref.invalidate(allEntriesProvider);
      await loadEntries();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }
}

final journalsProvider = StateNotifierProvider<JournalsNotifier, AsyncValue<List<JournalEntry>>>((ref) {
  final repo = ref.watch(journalRepositoryProvider);
  ref.watch(searchQueryProvider);
  ref.watch(selectedCategoryFilterProvider);
  ref.watch(selectedTagFilterProvider);
  ref.watch(selectedDateRangeFilterProvider);
  return JournalsNotifier(repo, ref);
});

// 5. Search and Filters State
final searchQueryProvider = StateProvider<String>((ref) => '');
final selectedCategoryFilterProvider = StateProvider<String?>((ref) => null);
final selectedTagFilterProvider = StateProvider<String?>((ref) => null);
final selectedDateRangeFilterProvider = StateProvider<DateTimeRange?>((ref) => null);

// 6. Filtered Entries Provider
final filteredEntriesProvider = Provider<AsyncValue<List<JournalEntry>>>((ref) {
  return ref.watch(journalsProvider);
});

// 7. Analytics Provider
final analyticsProvider = FutureProvider<AnalyticsData>((ref) async {
  final allEntriesState = ref.watch(allEntriesProvider);
  final repo = ref.watch(analyticsRepositoryProvider);
  
  return allEntriesState.when(
    loading: () => Completer<AnalyticsData>().future,
    error: (err, stack) => Future.error(err, stack),
    data: (entries) => repo.getAnalytics(entries),
  );
});

// 7.5. Calendar Highlights & Entries Providers
final calendarDatesProvider = FutureProvider.family<List<String>, String>((ref, yearMonth) async {
  final repo = ref.watch(journalRepositoryProvider);
  final parts = yearMonth.split('-');
  final year = int.parse(parts[0]);
  final month = int.parse(parts[1]);
  return repo.getCalendarDates(month, year);
});

final calendarEntriesProvider = FutureProvider.family<List<JournalEntry>, DateTime>((ref, date) async {
  final repo = ref.watch(journalRepositoryProvider);
  final startOfDay = DateTime(date.year, date.month, date.day);
  final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
  return repo.getEntries(
    startDate: startOfDay,
    endDate: endOfDay,
  );
});

class ExportsNotifier extends StateNotifier<List<ExportJob>> {
  final ExportRepository _repo;
  Timer? _pollingTimer;

  ExportsNotifier(this._repo) : super([]) {
    _refreshJobs();
    // Start interval refresh to check progress of running jobs
    _pollingTimer = Timer.periodic(const Duration(seconds: 2), (_) => _refreshJobs());
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _refreshJobs() async {
    try {
      final jobs = await _repo.getExportJobs();
      state = jobs;
    } catch (_) {}
  }

  Future<void> requestExport(String format) async {
    try {
      await _repo.requestExport(format);
      await _refreshJobs();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> retryExport(String exportId) async {
    try {
      await _repo.retryExport(exportId);
      await _refreshJobs();
    } catch (e) {
      rethrow;
    }
  }
}

final exportsProvider = StateNotifierProvider<ExportsNotifier, List<ExportJob>>((ref) {
  final repo = ref.watch(exportRepositoryProvider);
  return ExportsNotifier(repo);
});

// 9. Theme Mode Provider
class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.system);

  void toggleTheme() {
    if (state == ThemeMode.light) {
      state = ThemeMode.dark;
    } else {
      state = ThemeMode.light;
    }
  }

  void setTheme(ThemeMode mode) {
    state = mode;
  }
}

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});
