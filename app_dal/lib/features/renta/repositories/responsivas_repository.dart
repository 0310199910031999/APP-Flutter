import 'package:app_dal/core/constants/app_constants.dart';
import 'package:app_dal/features/renta/models/responsiva_record.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class ResponsivasRepository {
  ResponsivasRepository()
      : _dio = Dio(
          BaseOptions(
            baseUrl: AppConstants.baseUrl,
            connectTimeout: const Duration(seconds: 20),
            receiveTimeout: const Duration(seconds: 20),
          ),
        )..interceptors.add(
            LogInterceptor(
              requestBody: false,
              responseBody: true,
              logPrint: (o) => debugPrint(o.toString()),
            ),
          );

  final Dio _dio;

  Future<List<ResponsivaRecord>> fetchByClient(int clientId) async {
    try {
      final response = await _dio.get('${AppConstants.responsivasByClientEndpoint}/$clientId');

      if (response.statusCode == 200 && response.data is List) {
        final list = response.data as List;
        return list
            .whereType<Map<String, dynamic>>()
            .map(ResponsivaRecord.fromMap)
            .toList(growable: false);
      }

      throw Exception('Error al obtener responsivas (código: ${response.statusCode})');
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final data = e.response?.data;
      debugPrint('Responsivas error status=$status data=$data message=${e.message}');
      final msg = (data is Map && data['message'] != null)
          ? data['message'].toString()
          : (status != null
              ? 'No se pudieron obtener las responsivas (código: $status)'
              : 'No se pudieron obtener las responsivas');
      throw Exception(msg);
    } catch (e) {
      debugPrint('Responsivas unexpected error: $e');
      throw Exception('Error de conexión');
    }
  }
}
