class DashboardActivity {
  const DashboardActivity({
    required this.id,
    required this.format,
    required this.date,
    required this.employeeName,
    required this.status,
  });

  final int id;
  final String format;
  final DateTime? date;
  final String employeeName;
  final String status;

  factory DashboardActivity.fromMap(Map<String, dynamic> map) {
    return DashboardActivity(
      id: _asInt(map['id']),
      format: map['format']?.toString() ?? '',
      date: _asDate(map['date']),
      employeeName: map['employee_name']?.toString() ?? '',
      status: map['status']?.toString() ?? '',
    );
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse('$value') ?? 0;
  }

  static DateTime? _asDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }
}

class DashboardSummary {
  const DashboardSummary({
    required this.equipmentCount,
    required this.focr02Count,
    required this.openServices,
    required this.closedServices,
    required this.activity,
  });

  final int equipmentCount;
  final int focr02Count;
  final int openServices;
  final int closedServices;
  final List<DashboardActivity> activity;

  factory DashboardSummary.fromMap(Map<String, dynamic> map) {
    final activityList = map['activity'];
    return DashboardSummary(
      equipmentCount: _asInt(map['equipment_count']),
      focr02Count: _asInt(map['focr02_count']),
      openServices: _asInt(map['open_services']),
      closedServices: _asInt(map['closed_services']),
      activity: activityList is List
          ? activityList
              .whereType<Map<String, dynamic>>()
              .map(DashboardActivity.fromMap)
              .toList(growable: false)
          : const <DashboardActivity>[],
    );
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse('$value') ?? 0;
  }
}
