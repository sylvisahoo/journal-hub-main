import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../network/api_client.dart';
import '../models/models.dart';

class AuthRepository {
  final ApiClient _apiClient;

  AuthRepository(this._apiClient);

  User _decodeUserFromToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length == 3) {
        final payload = parts[1];
        var normalized = base64Url.normalize(payload);
        final decoded = utf8.decode(base64Url.decode(normalized));
        final map = json.decode(decoded) as Map<String, dynamic>;

        final exp = map['exp'] as int?;
        if (exp != null) {
          final expiryTime = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
          if (expiryTime.isBefore(DateTime.now())) {
            throw Exception('TOKEN_EXPIRED');
          }
        }

        return User(
          userId: map['userId'] ?? '',
          fullName: map['fullName'] ?? '',
          email: map['email'] ?? '',
          accountStatus: 'Verified',
        );
      }
    } catch (e) {
      rethrow;
    }
    throw Exception('INVALID_TOKEN');
  }

  Future<User?> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      if (token != null && token.isNotEmpty) {
        try {
          return _decodeUserFromToken(token);
        } catch (_) {
          await prefs.remove('access_token');
          await prefs.remove('refresh_token');
        }
      }
    } catch (_) {}
    return null;
  }

  Future<User> login(String email, String password) async {
    try {
      final response = await _apiClient.dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });

      final data = response.data;
      final accessToken = data['accessToken'] as String;
      final refreshToken = data['refreshToken'] as String;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', accessToken);
      await prefs.setString('refresh_token', refreshToken);

      return _decodeUserFromToken(accessToken);
    } on DioException catch (e) {
      if (e.response != null && e.response!.data != null) {
        final errCode = e.response!.data['errorCode'];
        throw Exception(errCode ?? 'LOGIN_FAILED');
      }
      throw Exception('CONNECTION_ERROR');
    }
  }

  Future<User> register(String fullName, String email, String password) async {
    try {
      final response = await _apiClient.dio.post('/auth/register', data: {
        'fullName': fullName,
        'email': email,
        'password': password,
      });

      final data = response.data;
      return User(
        userId: data['userId'],
        fullName: fullName,
        email: email,
        accountStatus: data['accountStatus'],
      );
    } on DioException catch (e) {
      if (e.response != null && e.response!.data != null) {
        final errCode = e.response!.data['errorCode'];
        throw Exception(errCode ?? 'REGISTRATION_FAILED');
      }
      throw Exception('CONNECTION_ERROR');
    }
  }

  Future<void> verifyEmail(String token) async {
    try {
      await _apiClient.dio.post('/auth/verify-email', data: {
        'verificationToken': token,
      });
    } on DioException catch (e) {
      if (e.response != null && e.response!.data != null) {
        final errCode = e.response!.data['errorCode'];
        throw Exception(errCode ?? 'VERIFICATION_FAILED');
      }
      throw Exception('CONNECTION_ERROR');
    }
  }

  Future<void> forgotPassword(String email) async {
    try {
      await _apiClient.dio.post('/auth/forgot-password', data: {
        'email': email,
      });
    } on DioException catch (e) {
      if (e.response != null && e.response!.data != null) {
        final errCode = e.response!.data['errorCode'];
        throw Exception(errCode ?? 'FORGOT_PASSWORD_FAILED');
      }
      throw Exception('CONNECTION_ERROR');
    }
  }

  Future<void> resetPassword(String token, String newPassword) async {
    try {
      await _apiClient.dio.post('/auth/reset-password', data: {
        'resetToken': token,
        'newPassword': newPassword,
      });
    } on DioException catch (e) {
      if (e.response != null && e.response!.data != null) {
        final errCode = e.response!.data['errorCode'];
        throw Exception(errCode ?? 'RESET_PASSWORD_FAILED');
      }
      throw Exception('CONNECTION_ERROR');
    }
  }

  Future<void> logout() async {
    try {
      await _apiClient.dio.post('/auth/logout');
    } catch (_) {
      // Swallowed to allow local logout to complete
    } finally {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('access_token');
      await prefs.remove('refresh_token');
    }
  }
}
