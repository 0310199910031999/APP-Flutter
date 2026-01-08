import 'package:app_dal/core/constants/app_constants.dart';
import 'package:app_dal/features/equipos/models/inspection_record.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class InspectionRecordsRepository {
  InspectionRecordsRepository()
    : _dio =
          Dio(
              BaseOptions(
                baseUrl: AppConstants.baseUrl,
                connectTimeout: const Duration(seconds: 20),
                receiveTimeout: const Duration(seconds: 20),
              ),
            )
            ..interceptors.add(
              LogInterceptor(
                requestBody: false,
                responseBody: true,
                logPrint: (o) => debugPrint(o.toString()),
              ),
            );

  final Dio _dio;

  Future<List<InspectionRecord>> fetchByEquipmentId(int equipmentId) async {
    try {
      final response = await _dio.get(
        '${AppConstants.inspectionRecordsEndpoint}/$equipmentId',
      );

      if (response.statusCode == 200 && response.data is List) {
        final list = response.data as List;
        return list
            .whereType<Map<String, dynamic>>()
            .map(InspectionRecord.fromMap)
            .toList();
      }

      throw Exception(
        'Error al obtener inspecciones (código: ${response.statusCode})',
      );
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final data = e.response?.data;
      debugPrint(
        'Inspection records error status=$status data=$data message=${e.message}',
      );
      final msg = (data is Map && data['message'] != null)
          ? data['message'].toString()
          : (status != null
                ? 'No se pudieron obtener las inspecciones (código: $status)'
                : 'No se pudieron obtener las inspecciones');
      throw Exception(msg);
    } catch (e) {
      debugPrint('Inspection records unexpected error: $e');
      throw Exception('Error de conexión');
    }
  }
}
