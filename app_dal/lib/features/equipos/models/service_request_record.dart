import 'package:app_dal/features/equipos/models/service_option.dart';
import 'package:app_dal/features/equipos/models/spare_part.dart';

class ServiceRequestRecord {
  const ServiceRequestRecord({
    required this.id,
    required this.clientId,
    required this.equipmentId,
    required this.appUserId,
    required this.serviceName,
    required this.requestType,
    required this.status,
    required this.serviceId,
    required this.sparePartId,
    this.dateCreated,
    this.dateClosed,
    this.service,
    this.sparePart,
  });

  final int id;
  final int clientId;
  final int equipmentId;
  final int appUserId;
  final String serviceName;
  final String requestType;
  final String status;
  final int serviceId;
  final int sparePartId;
  final DateTime? dateCreated;
  final DateTime? dateClosed;
  final ServiceOption? service;
  final SparePart? sparePart;

  factory ServiceRequestRecord.fromMap(Map<String, dynamic> map) {
    return ServiceRequestRecord(
      id: _asInt(map['id']),
      clientId: _asInt(map['client_id']),
      equipmentId: _asInt(map['equipment_id']),
      appUserId: _asInt(map['app_user_id']),
      serviceName: map['service_name']?.toString().trim() ?? '',
      requestType: map['request_type']?.toString().trim() ?? '',
      status: map['status']?.toString().trim() ?? '',
      serviceId: _asInt(map['service_id']),
      sparePartId: _asInt(map['spare_part_id']),
      dateCreated: _asDateTime(map['date_created']),
      dateClosed: _asDateTime(map['date_closed']),
      service: (map['service'] is Map<String, dynamic>)
          ? ServiceOption.fromMap(map['service'] as Map<String, dynamic>)
          : null,
      sparePart: _mapToSparePart(map),
    );
  }

  static SparePart? _mapToSparePart(Map<String, dynamic> map) {
    final raw = map['spare_part'] ?? map['sparePart'];
    if (raw is Map<String, dynamic>) {
      return SparePart.fromMap(raw);
    }
    return null;
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse('$value') ?? 0;
  }

  static DateTime? _asDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }
}
