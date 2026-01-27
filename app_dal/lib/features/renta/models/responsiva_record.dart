class ResponsivaRecord {
  const ResponsivaRecord({
    required this.id,
    required this.status,
    this.fileId,
    this.dateCreated,
    this.dateSigned,
    this.clientName,
    this.employeeName,
    this.receptionName,
    this.equipmentBrand,
    this.equipmentModel,
    this.equipmentSerial,
    this.equipmentEconomicNumber,
    this.equipmentType,
  });

  final int id;
  final String status;
  final String? fileId;
  final DateTime? dateCreated;
  final DateTime? dateSigned;
  final String? clientName;
  final String? employeeName;
  final String? receptionName;
  final String? equipmentBrand;
  final String? equipmentModel;
  final String? equipmentSerial;
  final String? equipmentEconomicNumber;
  final String? equipmentType;

  factory ResponsivaRecord.fromMap(Map<String, dynamic> map) {
    final equipment = map['equipment'] as Map<String, dynamic>?;
    final addedEquipment = map['focr_add_equipment'] as Map<String, dynamic>?;
    final brandMap = equipment?['brand'] as Map<String, dynamic>?;
    final typeMap = equipment?['type'] as Map<String, dynamic>?;

    return ResponsivaRecord(
      id: _asInt(map['id']),
      status: map['status']?.toString() ?? '',
      fileId: _asNullableString(map['file_id']),
      dateCreated: _asDate(map['date_created']),
      dateSigned: _asDate(map['date_signed']),
      clientName: _asNullableString((map['client'] as Map<String, dynamic>?)?['name']),
      employeeName: _formatEmployee(map['employee'] as Map<String, dynamic>?),
      receptionName: _asNullableString(map['reception_name']),
      equipmentBrand: _asNullableString(brandMap?['name']) ?? _asNullableString(addedEquipment?['brand']),
      equipmentModel: _asNullableString(equipment?['model']) ?? _asNullableString(addedEquipment?['model']),
      equipmentSerial:
          _asNullableString(equipment?['serial_number']) ?? _asNullableString(addedEquipment?['serial_number']),
      equipmentEconomicNumber: _asNullableString(equipment?['economic_number']) ??
          _asNullableString(addedEquipment?['economic_number']),
      equipmentType: _asNullableString(typeMap?['name']) ?? _asNullableString(addedEquipment?['equipment_type']),
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

  static DateTime? _asDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }

  static String? _formatEmployee(Map<String, dynamic>? employee) {
    if (employee == null) return null;
    final name = _asNullableString(employee['name']) ?? '';
    final last = _asNullableString(employee['lastname']) ?? '';
    final full = '$name $last'.trim();
    return full.isEmpty ? null : full;
  }

  @override
  String toString() {
    return 'ResponsivaRecord(id: $id, status: $status, fileId: $fileId, equipment: $equipmentBrand $equipmentModel)';
  }
}
