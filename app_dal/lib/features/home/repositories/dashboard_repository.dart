import 'package:app_dal/core/constants/app_constants.dart';
import 'package:app_dal/features/home/models/dashboard_summary.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class DashboardRepository {
  DashboardRepository()
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

  Future<DashboardSummary> fetchSummary(int clientId) async {
    try {
      final response = await _dio.get(
        '${AppConstants.dashboardMobileEndpoint}/$clientId',
      );

      if (response.statusCode == 200 && response.data is Map) {
        return DashboardSummary.fromMap(
          response.data as Map<String, dynamic>,
        );
      }

      throw Exception(
        'Error al obtener el resumen (código: ${response.statusCode})',
      );
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final data = e.response?.data;
      debugPrint('Dashboard error status=$status data=$data message=${e.message}');
      final msg = (data is Map && data['message'] != null)
          ? data['message'].toString()
          : (status != null
              ? 'No se pudo obtener el resumen (código: $status)'
              : 'No se pudo obtener el resumen');
      throw Exception(msg);
    } catch (e) {
      debugPrint('Dashboard unexpected error: $e');
      throw Exception('Error de conexión');
    }
  }
}
