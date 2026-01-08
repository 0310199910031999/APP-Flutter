import 'package:app_dal/features/equipos/models/spare_part_category.dart';

class SparePart {
  const SparePart({
    required this.id,
    required this.description,
    required this.categoryId,
    this.category,
  });

  final int id;
  final String description;
  final int categoryId;
  final SparePartCategory? category;

  factory SparePart.fromMap(Map<String, dynamic> map) {
    return SparePart(
      id: _asInt(map['id']),
      description: map['description']?.toString().trim() ?? '',
      categoryId: _asInt(map['category_id']),
      category: (map['category'] is Map<String, dynamic>)
          ? SparePartCategory.fromMap(map['category'] as Map<String, dynamic>)
          : null,
    );
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse('$value') ?? 0;
  }
}
