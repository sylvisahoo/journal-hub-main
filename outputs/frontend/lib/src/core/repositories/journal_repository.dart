import 'package:dio/dio.dart';
import '../network/api_client.dart';
import '../models/models.dart';

class JournalRepository {
  final ApiClient _apiClient;
  final List<Category> categories = [];
  final List<Tag> tags = [];

  JournalRepository(this._apiClient);

  Future<void> loadMetadata() async {
    try {
      await Future.wait([
        fetchCategories(),
        fetchTags(),
      ]);
    } catch (_) {
      // Swallowed to allow app initialization to proceed even if offline
    }
  }

  Future<List<Category>> fetchCategories() async {
    try {
      final response = await _apiClient.dio.get('/categories');
      final data = response.data as List;
      final list = data.map((item) {
        return Category(
          categoryId: item['categoryId'] as String,
          name: item['categoryName'] as String,
        );
      }).toList();
      categories.clear();
      categories.addAll(list);
      return list;
    } on DioException catch (e) {
      if (e.response != null && e.response!.data != null) {
        final errCode = e.response!.data['errorCode'];
        throw Exception(errCode ?? 'FETCH_CATEGORIES_FAILED');
      }
      throw Exception('CONNECTION_ERROR');
    }
  }

  Future<List<Tag>> fetchTags() async {
    try {
      final response = await _apiClient.dio.get('/tags');
      final data = response.data as List;
      final list = data.map((item) {
        return Tag(
          tagId: item['tagId'] as String,
          name: item['tagName'] as String,
        );
      }).toList();
      tags.clear();
      tags.addAll(list);
      return list;
    } on DioException catch (e) {
      if (e.response != null && e.response!.data != null) {
        final errCode = e.response!.data['errorCode'];
        throw Exception(errCode ?? 'FETCH_TAGS_FAILED');
      }
      throw Exception('CONNECTION_ERROR');
    }
  }

  Future<Category> createCategory(String name) async {
    try {
      final response = await _apiClient.dio.post('/categories', data: {
        'categoryName': name,
      });
      final newCat = Category(
        categoryId: response.data['categoryId'] as String,
        name: response.data['categoryName'] as String,
      );
      categories.add(newCat);
      return newCat;
    } on DioException catch (e) {
      if (e.response != null && e.response!.data != null) {
        final errCode = e.response!.data['errorCode'];
        throw Exception(errCode ?? 'CREATE_CATEGORY_FAILED');
      }
      throw Exception('CONNECTION_ERROR');
    }
  }

  Future<void> deleteCategory(String categoryId) async {
    // Backend API does not expose a category deletion endpoint.
    // Kept for backward compatibility as a successful no-op.
    return;
  }

  Future<Tag> createTag(String name) async {
    try {
      final response = await _apiClient.dio.post('/tags', data: {
        'tagName': name,
      });
      final newTag = Tag(
        tagId: response.data['tagId'] as String,
        name: response.data['tagName'] as String,
      );
      tags.add(newTag);
      return newTag;
    } on DioException catch (e) {
      if (e.response != null && e.response!.data != null) {
        final errCode = e.response!.data['errorCode'];
        throw Exception(errCode ?? 'CREATE_TAG_FAILED');
      }
      throw Exception('CONNECTION_ERROR');
    }
  }

  Future<void> deleteTag(String tagId) async {
    // Backend API does not expose a tag deletion endpoint.
    // Kept for backward compatibility as a successful no-op.
    return;
  }

  JournalEntry _mapJsonToEntry(Map<String, dynamic> json) {
    return JournalEntry(
      journalId: json['journalId'] as String,
      userId: json['userId'] as String,
      categoryId: json['categoryId'] as String?,
      title: json['title'] as String,
      content: json['content'] as String,
      entryDate: DateTime.parse(json['entryDate'] as String),
      tagIds: List<String>.from(json['tags'] ?? []),
      wordCount: json['wordCount'] as int,
      isPrivate: json['isPrivate'] as bool,
      versionNumber: json['versionNumber'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Future<List<JournalEntry>> getEntries({
    String? keyword,
    String? categoryId,
    String? tagId,
    DateTime? startDate,
    DateTime? endDate,
    int? page,
    int? limit,
  }) async {
    try {
      final queryParams = {
        if (keyword != null && keyword.isNotEmpty) 'keyword': keyword,
        if (categoryId != null && categoryId.isNotEmpty) 'category': categoryId,
        if (tagId != null && tagId.isNotEmpty) 'tag': tagId,
        if (startDate != null) 'startDate': startDate.toUtc().toIso8601String(),
        if (endDate != null) 'endDate': endDate.toUtc().toIso8601String(),
        if (page != null) 'page': page,
        if (limit != null) 'limit': limit,
      };
      final response = await _apiClient.dio.get('/journals', queryParameters: queryParams);
      final data = response.data as List;
      return data.map((json) => _mapJsonToEntry(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      if (e.response != null && e.response!.data != null) {
        final errCode = e.response!.data['errorCode'];
        throw Exception(errCode ?? 'FETCH_ENTRIES_FAILED');
      }
      throw Exception('CONNECTION_ERROR');
    }
  }

  Future<List<String>> getCalendarDates(int month, int year) async {
    try {
      final response = await _apiClient.dio.get('/calendar', queryParameters: {
        'month': month,
        'year': year,
      });
      final data = response.data as List;
      return List<String>.from(data);
    } on DioException catch (e) {
      if (e.response != null && e.response!.data != null) {
        final errCode = e.response!.data['errorCode'];
        throw Exception(errCode ?? 'FETCH_CALENDAR_FAILED');
      }
      throw Exception('CONNECTION_ERROR');
    }
  }

  Future<JournalEntry> createEntry(JournalEntry entry) async {
    try {
      final response = await _apiClient.dio.post('/journals', data: {
        'title': entry.title,
        'content': entry.content,
        'entryDate': entry.entryDate.toIso8601String(),
        if (entry.categoryId != null && entry.categoryId!.isNotEmpty) 'categoryId': entry.categoryId,
        'tags': entry.tagIds,
        'isPrivate': entry.isPrivate,
      });
      return _mapJsonToEntry(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response != null && e.response!.data != null) {
        final errCode = e.response!.data['errorCode'];
        throw Exception(errCode ?? 'CREATE_ENTRY_FAILED');
      }
      throw Exception('CONNECTION_ERROR');
    }
  }

  Future<JournalEntry> updateEntry(JournalEntry entry) async {
    try {
      final response = await _apiClient.dio.put('/journals/${entry.journalId}', data: {
        'title': entry.title,
        'content': entry.content,
        'entryDate': entry.entryDate.toIso8601String(),
        'categoryId': entry.categoryId,
        'tags': entry.tagIds,
        'isPrivate': entry.isPrivate,
        'versionNumber': entry.versionNumber,
      });
      return _mapJsonToEntry(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response != null && e.response!.data != null) {
        final errCode = e.response!.data['errorCode'];
        throw Exception(errCode ?? 'UPDATE_ENTRY_FAILED');
      }
      throw Exception('CONNECTION_ERROR');
    }
  }

  Future<void> deleteEntry(String journalId, {bool permanent = false}) async {
    try {
      await _apiClient.dio.delete(
        '/journals/$journalId',
        queryParameters: {
          if (permanent) 'permanent': 'true',
        },
      );
    } on DioException catch (e) {
      if (e.response != null && e.response!.data != null) {
        final errCode = e.response!.data['errorCode'];
        throw Exception(errCode ?? 'DELETE_ENTRY_FAILED');
      }
      throw Exception('CONNECTION_ERROR');
    }
  }

  Future<String> generateShareLink(String journalId) async {
    try {
      final response = await _apiClient.dio.post('/journals/$journalId/share');
      return response.data['shareUrl'] as String;
    } on DioException catch (e) {
      if (e.response != null && e.response!.data != null) {
        final errCode = e.response!.data['errorCode'];
        throw Exception(errCode ?? 'SHARE_LINK_FAILED');
      }
      throw Exception('CONNECTION_ERROR');
    }
  }
}
