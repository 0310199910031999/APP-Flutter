import 'package:app_dal/core/constants/app_constants.dart';
import 'package:app_dal/features/equipos/models/foim_question.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class FoimRepository {
  FoimRepository()
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

  Future<List<FoimQuestion>> fetchQuestions() async {
    try {
      final response = await _dio.get(AppConstants.foimQuestionsEndpoint);
      if (response.statusCode == 200 && response.data is List) {
        return (response.data as List)
            .whereType<Map<String, dynamic>>()
            .map(FoimQuestion.fromMap)
            .toList();
      }
      throw Exception(
        'Error al obtener preguntas (código: ${response.statusCode})',
      );
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final data = e.response?.data;
      debugPrint('FOIM questions error status=$status data=$data message=${e.message}');
      final msg = (data is Map && data['message'] != null)
          ? data['message'].toString()
          : (status != null
              ? 'No se pudieron obtener las preguntas (código: $status)'
              : 'No se pudieron obtener las preguntas');
      throw Exception(msg);
    } catch (e) {
      debugPrint('FOIM questions unexpected error: $e');
      throw Exception('Error de conexión');
    }
  }

  Future<void> createFoim03({
    required int equipmentId,
    required int appUserId,
    required DateTime dateCreated,
    required List<Foim03Answer> answers,
    int? employeeId,
  }) async {
    try {
      final payload = <String, dynamic>{
        'equipment_id': equipmentId,
        'app_user_id': appUserId,
        'date_created': _formatDate(dateCreated),
        'status': 'Nuevo',
        'foim03_answers': answers.map((a) => a.toJson()).toList(),
      };
      if (employeeId != null) {
        payload['employee_id'] = employeeId;
      }

      final response = await _dio.post(
        AppConstants.foimCreateEndpoint,
        data: payload,
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception(
          'No se pudo guardar la inspección (código: ${response.statusCode})',
        );
      }
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final data = e.response?.data;
      debugPrint('FOIM create error status=$status data=$data message=${e.message}');
      final msg = (data is Map && data['message'] != null)
          ? data['message'].toString()
          : (status != null
              ? 'No se pudo guardar la inspección (código: $status)'
              : 'No se pudo guardar la inspección');
      throw Exception(msg);
    } catch (e) {
      debugPrint('FOIM create unexpected error: $e');
      throw Exception('Error de conexión');
    }
  }

  String _formatDate(DateTime date) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${date.year}-${two(date.month)}-${two(date.day)}';
  }
}
