class SparePartCategory {
  const SparePartCategory({required this.id, required this.description});

  final int id;
  final String description;

  factory SparePartCategory.fromMap(Map<String, dynamic> map) {
    return SparePartCategory(
      id: _asInt(map['id']),
      description: map['description']?.toString().trim() ?? '',
    );
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse('$value') ?? 0;
  }
}
