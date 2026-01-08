import 'package:app_dal/core/constants/app_constants.dart';
import 'package:app_dal/features/equipos/models/service_option.dart';
import 'package:app_dal/features/equipos/models/service_request_record.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class ServiceRequestsRepository {
  ServiceRequestsRepository()
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
              logPrint: (o) => debugPrint(o.toString()),
            ),
          );

  final Dio _dio;

  Future<List<ServiceOption>> fetchServices() async {
    try {
      final response = await _dio.get(AppConstants.servicesEndpoint);

      if (response.statusCode == 200 && response.data is List) {
        final list = response.data as List;
        return list
            .whereType<Map<String, dynamic>>()
            .map(ServiceOption.fromMap)
            .toList(growable: false);
      }

      throw Exception('Error al obtener servicios (código: ${response.statusCode})');
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final data = e.response?.data;
      debugPrint('Servicios error status=$status data=$data message=${e.message}');
      final msg = (data is Map && data['message'] != null)
          ? data['message'].toString()
          : (status != null
              ? 'No se pudieron obtener los servicios (código: $status)'
              : 'No se pudieron obtener los servicios');
      throw Exception(msg);
    } catch (e) {
      debugPrint('Servicios unexpected error: $e');
      throw Exception('Error de conexión');
    }
  }

  Future<void> createRequest({
    required int clientId,
    required int equipmentId,
    required int appUserId,
    String? serviceName,
    int? serviceId,
    int? sparePartId,
    required String requestType,
    String status = 'Abierto',
  }) async {
    try {
      final sanitizedServiceId = (serviceId != null && serviceId > 0) ? serviceId : null;
      final sanitizedSparePartId =
          (sparePartId != null && sparePartId > 0) ? sparePartId : null;
      final normalizedServiceName = serviceName?.trim() ?? '';

      final hasServiceOrSpare =
          sanitizedServiceId != null || sanitizedSparePartId != null;
      final hasServiceName = normalizedServiceName.isNotEmpty;

      if (!hasServiceOrSpare && !hasServiceName) {
        throw Exception(
          'Debes seleccionar un servicio, una refacción o agregar una descripción.',
        );
      }

      final payload = <String, dynamic>{
        'client_id': clientId,
        'equipment_id': equipmentId,
        'app_user_id': appUserId,
        'status': status,
        'request_type': requestType,
        'service_id': sanitizedServiceId,
        'spare_part_id': sanitizedSparePartId,
        if (hasServiceName) 'service_name': normalizedServiceName,
      };

      final response = await _dio.post(
        AppConstants.appRequestsCreateEndpoint,
        data: payload,
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception(
          'No se pudo crear la solicitud (código: ${response.statusCode})',
        );
      }
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final data = e.response?.data;
      debugPrint('Crear solicitud error status=$status data=$data message=${e.message}');
      final msg = (data is Map && data['message'] != null)
          ? data['message'].toString()
          : (status != null
              ? 'No se pudo crear la solicitud (código: $status)'
              : 'No se pudo crear la solicitud');
      throw Exception(msg);
    } catch (e) {
      debugPrint('Crear solicitud unexpected error: $e');
      throw Exception('Error de conexión');
    }
  }

  Future<List<ServiceRequestRecord>> fetchRequestsByEquipmentId(int equipmentId) async {
    try {
      final response = await _dio.get(
        '${AppConstants.appRequestsByEquipmentEndpoint}/$equipmentId',
      );

      if (response.statusCode == 200 && response.data is List) {
        final list = response.data as List;
        return list
            .whereType<Map<String, dynamic>>()
            .map(ServiceRequestRecord.fromMap)
            .toList(growable: false);
      }

      throw Exception(
        'Error al obtener solicitudes (código: ${response.statusCode})',
      );
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final data = e.response?.data;
      debugPrint('App requests error status=$status data=$data message=${e.message}');
      final msg = (data is Map && data['message'] != null)
          ? data['message'].toString()
          : (status != null
              ? 'No se pudieron obtener las solicitudes (código: $status)'
              : 'No se pudieron obtener las solicitudes');
      throw Exception(msg);
    } catch (e) {
      debugPrint('App requests unexpected error: $e');
      throw Exception('Error de conexión');
    }
  }

  /// Devuelve solo solicitudes ligadas a servicios (excluye refacciones).
  Future<List<ServiceRequestRecord>> fetchServiceRequestsByEquipmentId(
    int equipmentId,
  ) async {
    final all = await fetchRequestsByEquipmentId(equipmentId);
    return all
        .where((r) => r.sparePartId == 0)
        .where((r) =>
            r.service != null || r.serviceId != 0 || r.serviceName.trim().isNotEmpty)
        .toList(growable: false);
  }

  /// Devuelve solo solicitudes de refacciones (excluye servicios).
  Future<List<ServiceRequestRecord>> fetchSparePartRequestsByEquipmentId(
    int equipmentId,
  ) async {
    final all = await fetchRequestsByEquipmentId(equipmentId);
    return all.where((r) => r.sparePartId != 0).toList(growable: false);
  }
}
