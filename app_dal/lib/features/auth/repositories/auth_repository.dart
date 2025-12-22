import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_dal/core/constants/app_constants.dart';

class AuthRepository {
  final SharedPreferences _prefs;
  final Dio _dio;

  AuthRepository(this._prefs)
      : _dio = Dio(
          BaseOptions(
            baseUrl: AppConstants.baseUrl,
            connectTimeout: const Duration(seconds: 20),
            receiveTimeout: const Duration(seconds: 20),
            sendTimeout: const Duration(seconds: 20),
            headers: {'Content-Type': 'application/json'},
          ),
        )..interceptors.add(
            LogInterceptor(
              requestBody: true,
              responseBody: true,
              logPrint: (obj) => debugPrint(obj.toString()),
            ),
          );

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _dio.post(
        AppConstants.loginEndpoint,
        data: {
          'email': email,
          'password': password,
        },
      );

      if (response.statusCode == 200 && response.data is Map) {
        final userData = Map<String, dynamic>.from(response.data as Map);

        await _prefs.setBool(AppConstants.isLoggedInKey, true);
        await _prefs.setString(AppConstants.userEmailKey, userData['email']?.toString() ?? '');
        await _prefs.setString(AppConstants.userDataKey, jsonEncode(userData));

        return userData;
      }

      throw Exception('Error en login (código: ${response.statusCode})');
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final data = e.response?.data;
      debugPrint('Auth login error status=$status data=$data message=${e.message}');

      final msg = (data is Map && data['message'] != null)
          ? data['message'].toString()
          : (status != null ? 'No se pudo iniciar sesión (código: $status)' : 'No se pudo iniciar sesión');
      throw Exception(msg);
    } catch (e) {
      debugPrint('Auth login unexpected error: $e');
      throw Exception('Error de conexión');
    }
  }

  Future<bool> isLoggedIn() async {
    return _prefs.getBool(AppConstants.isLoggedInKey) ?? false;
  }

  String? getSavedEmail() {
    return _prefs.getString(AppConstants.userEmailKey);
  }

  Map<String, dynamic>? getSavedUser() {
    final json = _prefs.getString(AppConstants.userDataKey);
    if (json == null) return null;
    try {
      return Map<String, dynamic>.from(jsonDecode(json) as Map);
    } catch (_) {
      return null;
    }
  }

  Future<void> logout() async {
    await _prefs.remove(AppConstants.isLoggedInKey);
    await _prefs.remove(AppConstants.userEmailKey);
    await _prefs.remove(AppConstants.userTokenKey);
    await _prefs.remove(AppConstants.userDataKey);
  }
}
