import 'package:app_dal/core/constants/app_constants.dart';
import 'package:flutter/foundation.dart';

class Equipo {
  const Equipo({
    required this.id,
    required this.clientId,
    this.clientName = '',
    required this.type,
    required this.brand,
    required this.model,
    required this.mast,
    required this.serialNumber,
    required this.hourometer,
    required this.doh,
    required this.economicNumber,
    required this.capacity,
    required this.addition,
    required this.motor,
    required this.property,
    this.status = '',
  });

  final int id;
  final int clientId;
  final String clientName;
  final EquipoType type;
  final EquipoBrand brand;
  final String model;
  final String mast;
  final String serialNumber;
  final num hourometer;
  final num doh;
  final String economicNumber;
  final String capacity;
  final String addition;
  final String motor;
  final String property;
  final String status;

  String? get brandImageUrl {
    if (brand.imgPath == null || brand.imgPath!.isEmpty) {
      return null;
    }
    final trimmed = brand.imgPath!.replaceFirst(RegExp(r'^/+'), '');
    final url = '${AppConstants.baseUrl}${AppConstants.staticBrandPath}$trimmed';
    debugPrint('Equipo brand image URL: $url');
    return url;
  }

  factory Equipo.fromMap(Map<String, dynamic> map) {
    return Equipo(
      id: _asInt(map['id']),
      clientId: _asInt(map['client_id']),
      clientName: map['client_name']?.toString() ?? '',
      type: EquipoType.fromMap(map['type'] as Map<String, dynamic>? ?? const {}),
      brand: EquipoBrand.fromMap(map['brand'] as Map<String, dynamic>? ?? const {}),
      model: map['model']?.toString() ?? '',
      mast: map['mast']?.toString() ?? '',
      serialNumber: map['serial_number']?.toString() ?? '',
      hourometer: _asNum(map['hourometer']),
      doh: _asNum(map['doh']),
      economicNumber: map['economic_number']?.toString() ?? '',
      capacity: map['capacity']?.toString() ?? '',
      addition: map['addition']?.toString() ?? '',
      motor: map['motor']?.toString() ?? '',
      property: map['property']?.toString() ?? '',
      status: map['status']?.toString() ?? '',
    );
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse('$value') ?? 0;
  }

  static num _asNum(dynamic value) {
    if (value is num) return value;
    return num.tryParse('$value') ?? 0;
  }
}

class EquipoType {
  const EquipoType({required this.id, required this.name});

  final int id;
  final String name;

  factory EquipoType.fromMap(Map<String, dynamic> map) {
    return EquipoType(
      id: Equipo._asInt(map['id']),
      name: map['name']?.toString() ?? '',
    );
  }
}

class EquipoBrand {
  const EquipoBrand({required this.id, required this.name, this.imgPath});

  final int id;
  final String name;
  final String? imgPath;

  factory EquipoBrand.fromMap(Map<String, dynamic> map) {
    return EquipoBrand(
      id: Equipo._asInt(map['id']),
      name: map['name']?.toString() ?? '',
      imgPath: map['img_path']?.toString(),
    );
  }
}
