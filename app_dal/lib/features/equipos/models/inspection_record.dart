class InspectionRecord {
  const InspectionRecord({
    required this.id,
    required this.dateCreated,
    required this.observations,
    required this.employeeName,
    required this.appUserName,
    required this.status,
  });

  final int id;
  final DateTime? dateCreated;
  final String? observations;
  final String? employeeName;
  final String? appUserName;
  final String? status;

  factory InspectionRecord.fromMap(Map<String, dynamic> map) {
    return InspectionRecord(
      id: _asInt(map['id']),
      dateCreated: _asDateTime(map['date_created']),
      observations: _asNullableString(map['observations']),
      employeeName: _asNullableString(map['employee_name']),
      appUserName: _asNullableString(map['app_user_name']),
      status: _asNullableString(map['status']),
    );
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse('$value') ?? 0;
  }

  static String? _asNullableString(dynamic value) {
    if (value == null) return null;
    final s = value.toString();
    return s.trim().isEmpty ? null : s;
  }

  static DateTime? _asDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }
}
