import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  final Dio dio;
  static void Function()? onUnauthorizedGlobal;

  ApiClient({String? overrideBaseUrl})
      : dio = Dio(
          BaseOptions(
            // Default to localhost:5001 matching backend, fallbacks for Android emulator loopback
            baseUrl: overrideBaseUrl ??
                (!kIsWeb && defaultTargetPlatform == TargetPlatform.android
                    ? 'http://10.0.2.2:5001/api/v1'
                    : 'http://localhost:5001/api/v1'),
            connectTimeout: const Duration(seconds: 60),
            receiveTimeout: const Duration(seconds: 60),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          ),
        ) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          try {
            final prefs = await SharedPreferences.getInstance();
            final token = prefs.getString('access_token');
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          } catch (_) {
            // Silently fail if local storage is not initialized
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) async {
          if (error.response?.statusCode == 401) {
            try {
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('access_token');
              await prefs.remove('refresh_token');
            } catch (_) {}
            if (onUnauthorizedGlobal != null) {
              onUnauthorizedGlobal!();
            }
          }
          return handler.next(error);
        },
      ),
    );
  }
}
