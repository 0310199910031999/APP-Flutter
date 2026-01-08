class ServiceOption {
  const ServiceOption({
    required this.id,
    required this.code,
    required this.name,
    required this.type,
    this.description,
  });

  final int id;
  final String code;
  final String name;
  final String type;
  final String? description;

  factory ServiceOption.fromMap(Map<String, dynamic> map) {
    return ServiceOption(
      id: _asInt(map['id']),
      code: map['code']?.toString().trim() ?? '',
      name: map['name']?.toString().trim() ?? '',
      type: map['type']?.toString().trim() ?? '',
      description: _asNullableString(map['description']),
    );
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse('$value') ?? 0;
  }

  static String? _asNullableString(dynamic value) {
    if (value == null) return null;
    final s = value.toString().trim();
    return s.isEmpty ? null : s;
  }
}
