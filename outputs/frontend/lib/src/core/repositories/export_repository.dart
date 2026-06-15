import 'package:dio/dio.dart';
import '../network/api_client.dart';
import '../models/models.dart';

class ExportRepository {
  final ApiClient _apiClient;

  ExportRepository(this._apiClient);

  ExportJob _mapJsonToJob(Map<String, dynamic> json) {
    return ExportJob(
      exportId: json['exportId'] as String,
      format: json['format'] as String,
      status: json['status'] as String,
      requestedAt: DateTime.parse(json['requestedAt'] as String),
      downloadUrl: json['downloadUrl'] as String?,
    );
  }

  Future<List<ExportJob>> getExportJobs() async {
    try {
      final response = await _apiClient.dio.get('/export');
      final data = response.data as List;
      return data.map((json) => _mapJsonToJob(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      if (e.response != null && e.response!.data != null) {
        final errCode = e.response!.data['errorCode'];
        throw Exception(errCode ?? 'FETCH_EXPORTS_FAILED');
      }
      throw Exception('CONNECTION_ERROR');
    }
  }

  Future<ExportJob> requestExport(String format) async {
    try {
      final response = await _apiClient.dio.post('/export', data: {
        'format': format,
      });
      return _mapJsonToJob(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response != null && e.response!.data != null) {
        final errCode = e.response!.data['errorCode'];
        throw Exception(errCode ?? 'EXPORT_REQUEST_FAILED');
      }
      throw Exception('CONNECTION_ERROR');
    }
  }

  Future<ExportJob> getExportStatus(String exportId) async {
    try {
      final response = await _apiClient.dio.get('/export/$exportId');
      return _mapJsonToJob(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response != null && e.response!.data != null) {
        final errCode = e.response!.data['errorCode'];
        throw Exception(errCode ?? 'EXPORT_STATUS_FAILED');
      }
      throw Exception('CONNECTION_ERROR');
    }
  }

  Future<ExportJob> retryExport(String exportId) async {
    try {
      final response = await _apiClient.dio.post('/export/$exportId/retry');
      return _mapJsonToJob(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response != null && e.response!.data != null) {
        final errCode = e.response!.data['errorCode'];
        throw Exception(errCode ?? 'EXPORT_RETRY_FAILED');
      }
      throw Exception('CONNECTION_ERROR');
    }
  }
}
