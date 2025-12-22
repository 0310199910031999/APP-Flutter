import 'package:app_dal/features/equipos/models/equipo.dart';
import 'package:app_dal/features/equipos/repositories/equipos_repository.dart';
import 'package:flutter/foundation.dart';

class EquiposProvider extends ChangeNotifier {
  EquiposProvider(this._repository);

  final EquiposRepository _repository;

  List<Equipo> _equipos = const [];
  bool _isLoading = false;
  String? _error;

  List<Equipo> get equipos => _equipos;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadEquipos(int clientId) async {
    if (clientId <= 0) {
      _error = 'Cliente no encontrado. Inicia sesión nuevamente.';
      _equipos = const [];
      _isLoading = false;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _equipos = await _repository.fetchByClient(clientId);
      debugPrint('Equipos cargados: ${_equipos.length}');
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
