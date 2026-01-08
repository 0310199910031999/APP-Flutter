class ServiceRecord {
  const ServiceRecord({
    required this.format,
    required this.id,
    required this.dateCreated,
    required this.employeeName,
    required this.status,
    required this.rating,
    required this.ratingComment,
    required this.fileId,
    required this.observations,
  });

  final String format;
  final int id;
  final DateTime? dateCreated;
  final String? employeeName;
  final String? status;
  final num? rating;
  final String? ratingComment;
  final String? fileId;
  final String? observations;

  factory ServiceRecord.fromMap(Map<String, dynamic> map) {
    return ServiceRecord(
      format: map['format']?.toString() ?? '',
      id: _asInt(map['id']),
      dateCreated: _asDateTime(map['date_created']),
      employeeName: _asNullableString(map['employee_name']),
      status: _asNullableString(map['status']),
      rating: _asNullableNum(map['rating']),
      ratingComment: _asNullableString(map['rating_comment']),
      fileId: _asNullableString(map['file_id']),
      observations: _asNullableString(map['observations']),
    );
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse('$value') ?? 0;
  }

  static num? _asNullableNum(dynamic value) {
    if (value == null) return null;
    if (value is num) return value;
    return num.tryParse('$value');
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
