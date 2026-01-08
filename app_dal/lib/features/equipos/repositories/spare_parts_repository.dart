import 'package:app_dal/core/constants/app_constants.dart';
import 'package:app_dal/features/equipos/models/spare_part.dart';
import 'package:app_dal/features/equipos/models/spare_part_category.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class SparePartsRepository {
  SparePartsRepository()
      : _dio = Dio(
          BaseOptions(
            baseUrl: AppConstants.baseUrl,
            connectTimeout: const Duration(seconds: 20),
            receiveTimeout: const Duration(seconds: 20),
            sendTimeout: const Duration(seconds: 20),
          ),
        )..interceptors.add(
            LogInterceptor(
              requestBody: false,
              responseBody: true,
              logPrint: (o) => debugPrint(o.toString()),
            ),
          );

  final Dio _dio;

  Future<List<SparePartCategory>> fetchCategories() async {
    try {
      final response = await _dio.get(AppConstants.sparePartCategoriesEndpoint);
      if (response.statusCode == 200 && response.data is List) {
        final list = response.data as List;
        return list
            .whereType<Map<String, dynamic>>()
            .map(SparePartCategory.fromMap)
            .toList(growable: false);
      }
      throw Exception('Error al obtener categorías (código: ${response.statusCode})');
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final data = e.response?.data;
      debugPrint('Categorías error status=$status data=$data message=${e.message}');
      final msg = (data is Map && data['message'] != null)
          ? data['message'].toString()
          : (status != null
              ? 'No se pudieron obtener las categorías (código: $status)'
              : 'No se pudieron obtener las categorías');
      throw Exception(msg);
    } catch (e) {
      debugPrint('Categorías unexpected error: $e');
      throw Exception('Error de conexión');
    }
  }

  Future<List<SparePart>> fetchSpareParts() async {
    try {
      final response = await _dio.get(AppConstants.sparePartsEndpoint);
      if (response.statusCode == 200 && response.data is List) {
        final list = response.data as List;
        return list
            .whereType<Map<String, dynamic>>()
            .map(SparePart.fromMap)
            .toList(growable: false);
      }
      throw Exception('Error al obtener refacciones (código: ${response.statusCode})');
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final data = e.response?.data;
      debugPrint('Refacciones error status=$status data=$data message=${e.message}');
      final msg = (data is Map && data['message'] != null)
          ? data['message'].toString()
          : (status != null
              ? 'No se pudieron obtener las refacciones (código: $status)'
              : 'No se pudieron obtener las refacciones');
      throw Exception(msg);
    } catch (e) {
      debugPrint('Refacciones unexpected error: $e');
      throw Exception('Error de conexión');
    }
  }
}
