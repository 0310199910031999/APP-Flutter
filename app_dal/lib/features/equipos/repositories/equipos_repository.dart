import 'package:app_dal/core/constants/app_constants.dart';
import 'package:app_dal/features/equipos/models/equipo.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class EquiposRepository {
  EquiposRepository()
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

  Future<List<Equipo>> fetchByClient(int clientId) async {
    try {
      final response = await _dio.get('${AppConstants.equipmentByClientEndpoint}/$clientId');

      if (response.statusCode == 200 && response.data is List) {
        final list = response.data as List;
        debugPrint('Equipos response length=${list.length}');
        final equipos = list
            .whereType<Map<String, dynamic>>()
            .map((e) {
              debugPrint('Equipo raw: $e');
              return Equipo.fromMap(e);
            })
            .toList();
        return equipos;
      }

      throw Exception('Error al obtener equipos (código: ${response.statusCode})');
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final data = e.response?.data;
      debugPrint('Equipos fetch error status=$status data=$data message=${e.message}');
      final msg = (data is Map && data['message'] != null)
          ? data['message'].toString()
          : (status != null ? 'No se pudieron obtener los equipos (código: $status)' : 'No se pudieron obtener los equipos');
      throw Exception(msg);
    } catch (e) {
      debugPrint('Equipos fetch unexpected error: $e');
      throw Exception('Error de conexión');
    }
  }

  Future<List<Equipo>> fetchByProperty(String property) async {
    try {
      final encoded = Uri.encodeComponent(property);
      final response = await _dio.get('${AppConstants.equipmentByPropertyEndpoint}/$encoded');

      if (response.statusCode == 200 && response.data is List) {
        final list = response.data as List;
        debugPrint('Equipos by property response length=${list.length}');
        return list
            .whereType<Map<String, dynamic>>()
            .map(Equipo.fromMap)
            .toList();
      }

      throw Exception('Error al obtener equipos (código: ${response.statusCode})');
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final data = e.response?.data;
      debugPrint('Equipos by property error status=$status data=$data message=${e.message}');
      final msg = (data is Map && data['message'] != null)
          ? data['message'].toString()
          : (status != null
              ? 'No se pudieron obtener los equipos (código: $status)'
              : 'No se pudieron obtener los equipos');
      throw Exception(msg);
    } catch (e) {
      debugPrint('Equipos by property unexpected error: $e');
      throw Exception('Error de conexión');
    }
  }

  Future<Equipo> fetchById(int equipmentId) async {
    try {
      final response = await _dio.get('${AppConstants.equipmentDetailEndpoint}/$equipmentId');

      if (response.statusCode == 200 && response.data is Map) {
        final map = response.data as Map<String, dynamic>;
        debugPrint('Equipo detail raw: $map');
        return Equipo.fromMap(map);
      }

      throw Exception('Error al obtener detalle (código: ${response.statusCode})');
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final data = e.response?.data;
      debugPrint('Equipo detail error status=$status data=$data message=${e.message}');
      final msg = (data is Map && data['message'] != null)
          ? data['message'].toString()
          : (status != null ? 'No se pudo obtener el equipo (código: $status)' : 'No se pudo obtener el equipo');
      throw Exception(msg);
    } catch (e) {
      debugPrint('Equipo detail unexpected error: $e');
      throw Exception('Error de conexión');
    }
  }

  Future<bool> updateHourometer({required int equipmentId, required double hourometer}) async {
    try {
      final response = await _dio.patch(
        '${AppConstants.equipmentDetailEndpoint}/$equipmentId/hourometer',
        data: {'hourometer': hourometer},
      );

      if (response.statusCode == 200 && response.data is bool) {
        return response.data == true;
      }

      throw Exception('No se pudo actualizar el horómetro (código: ${response.statusCode})');
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final data = e.response?.data;
      debugPrint('Hourometer update error status=$status data=$data message=${e.message}');
      final msg = (data is Map && data['message'] != null)
          ? data['message'].toString()
          : (status != null
              ? 'No se pudo actualizar el horómetro (código: $status)'
              : 'No se pudo actualizar el horómetro');
      throw Exception(msg);
    } catch (e) {
      debugPrint('Hourometer update unexpected error: $e');
      throw Exception('Error de conexión');
    }
  }
}
