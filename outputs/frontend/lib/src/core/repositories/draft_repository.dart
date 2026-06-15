import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../network/api_client.dart';

class DraftRepository {
  final ApiClient _apiClient;

  DraftRepository(this._apiClient);

  Future<Map<String, dynamic>> saveDraftRemote({
    String? draftId,
    String? journalId,
    String? title,
    String? content,
  }) async {
    try {
      final response = await _apiClient.dio.post('/drafts', data: {
        if (draftId != null && draftId.isNotEmpty) 'draftId': draftId,
        'journalId': journalId,
        'title': title ?? '',
        'content': content ?? '',
        'deviceIdentifier': 'mobile'
      });
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      if (e.response != null && e.response!.data != null) {
        final errCode = e.response!.data['errorCode'];
        throw Exception(errCode ?? 'SAVE_FAILED');
      }
      throw Exception('CONNECTION_ERROR');
    }
  }

  Future<Map<String, dynamic>> getDraftRemote(String draftId) async {
    try {
      final response = await _apiClient.dio.get('/drafts/$draftId');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      if (e.response != null && e.response!.data != null) {
        final errCode = e.response!.data['errorCode'];
        throw Exception(errCode ?? 'DRAFT_NOT_FOUND');
      }
      throw Exception('CONNECTION_ERROR');
    }
  }

  Future<void> saveDraftLocal({
    String? journalId,
    String? title,
    String? content,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'draft_${journalId ?? 'new'}';
      final value = json.encode({
        'title': title ?? '',
        'content': content ?? '',
        'journalId': journalId,
        'savedAt': DateTime.now().toIso8601String(),
      });
      await prefs.setString(key, value);
    } catch (_) {}
  }

  Future<Map<String, dynamic>?> getLocalDraft(String? journalId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'draft_${journalId ?? 'new'}';
      final value = prefs.getString(key);
      if (value != null && value.isNotEmpty) {
        return json.decode(value) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  Future<void> clearLocalDraft(String? journalId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'draft_${journalId ?? 'new'}';
      await prefs.remove(key);
    } catch (_) {}
  }
}
