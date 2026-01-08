import 'package:app_dal/features/equipos/models/equipo.dart';
import 'package:app_dal/features/equipos/presentation/detail/tabs/equipo_info_tab.dart';
import 'package:app_dal/features/equipos/presentation/detail/tabs/inspection_tab.dart';
import 'package:app_dal/features/equipos/presentation/detail/tabs/parts_request_tab.dart';
import 'package:app_dal/features/equipos/presentation/detail/tabs/service_history_tab.dart';
import 'package:app_dal/features/equipos/presentation/detail/tabs/service_request_tab.dart';
import 'package:app_dal/features/equipos/presentation/detail/widgets/error_view.dart';
import 'package:app_dal/features/equipos/repositories/equipos_repository.dart';
import 'package:flutter/material.dart';

class EquipoDetailScreen extends StatefulWidget {
  const EquipoDetailScreen({super.key, required this.equipoId});

  final int equipoId;

  @override
  State<EquipoDetailScreen> createState() => _EquipoDetailScreenState();
}

class _EquipoDetailScreenState extends State<EquipoDetailScreen> {
  final _repository = EquiposRepository();
  final PageController _pageController = PageController();

  Equipo? _equipo;
  Object? _error;
  bool _isInitialLoading = true;
  int _currentIndex = 0;

  static const _titles = <String>[
    'Equipo',
    'Historial de servicios',
    'Inspección visual',
    'Solicitud de servicio',
    'Solicitud de refacciones',
  ];

  @override
  void initState() {
    super.initState();
    _loadEquipo(initial: true);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadEquipo({bool initial = false}) async {
    if (initial) {
      setState(() {
        _isInitialLoading = true;
        _error = null;
      });
    }

    try {
      final equipo = await _repository.fetchById(widget.equipoId);
      if (!mounted) return;
      setState(() {
        _equipo = equipo;
        _error = null;
        _isInitialLoading = false;
      });
    } catch (err) {
      if (!mounted) return;
      setState(() {
        _error = err;
        _isInitialLoading = false;
      });
    }
  }

  void _onPageChanged(int index) {
    if (_currentIndex == index) return;
    setState(() {
      _currentIndex = index;
    });
  }

  void _onTapNavigation(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = _titles[_currentIndex];

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: _buildBody(),
      bottomNavigationBar: (_equipo == null && _isInitialLoading)
          ? null
          : BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: _onTapNavigation,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.info_outline),
                  label: 'Info',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.history),
                  label: 'Historial',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.fact_check_outlined),
                  label: 'Inspección',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.handyman_outlined),
                  label: 'Servicios',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.build_outlined),
                  label: 'Refacciones',
                ),
              ],
            ),
    );
  }

  Widget _buildBody() {
    if (_isInitialLoading && _equipo == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _equipo == null) {
      return ErrorView(
        title: 'No se pudo cargar el equipo',
        message: _error.toString(),
        onRetry: () => _loadEquipo(initial: true),
      );
    }

    final equipo = _equipo!;

    return PageView(
      controller: _pageController,
      onPageChanged: _onPageChanged,
      children: [
        EquipoInfoTab(
          equipo: equipo,
          onRefreshEquipo: _loadEquipo,
        ),
        ServiceHistoryTab(
          equipo: equipo,
        ),
        InspectionTab(
          equipo: equipo,
          onRefreshEquipo: _loadEquipo,
        ),
        ServiceRequestTab(
          equipo: equipo,
          onRefreshEquipo: _loadEquipo,
        ),
        PartsRequestTab(
          equipo: equipo,
          onRefreshEquipo: _loadEquipo,
        ),
      ],
    );
  }
}
