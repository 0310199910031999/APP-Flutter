import 'package:app_dal/features/auth/providers/auth_provider.dart';
import 'package:app_dal/features/equipos/models/equipo.dart';
import 'package:app_dal/features/equipos/presentation/report/reporte_screen.dart';
import 'package:app_dal/features/equipos/repositories/equipos_repository.dart';
import 'package:app_dal/features/equipos/repositories/service_requests_repository.dart';
import 'package:app_dal/features/renta/models/responsiva_record.dart';
import 'package:app_dal/features/renta/repositories/responsivas_repository.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class RentaTab extends StatefulWidget {
  const RentaTab({super.key});

  @override
  State<RentaTab> createState() => _RentaTabState();
}

class _RentaTabState extends State<RentaTab>
    with AutomaticKeepAliveClientMixin {
  static const String _propertyValue = 'DAL Dealer Group';

  final _equiposRepository = EquiposRepository();
  final _responsivasRepository = ResponsivasRepository();
  final _serviceRequestsRepository = ServiceRequestsRepository();

  bool _isLoadingEquipos = false;
  bool _isLoadingResponsivas = false;
  String? _equiposError;
  String? _responsivasError;
  List<Equipo> _equipos = const [];
  List<ResponsivaRecord> _responsivas = const [];
  int? _submittingEquipmentId;
  String? _submittingRequestType;

  // Cached filtered lists - computed once when data changes, not in build
  List<Equipo> _cachedAvailable = const [];
  List<Equipo> _cachedUpcoming = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshAll();
    });
  }

  @override
  bool get wantKeepAlive => true;

  Future<void> _refreshAll() async {
    await Future.wait([
      _loadEquipos(),
      _loadResponsivas(),
    ]);
  }

  Future<void> _loadEquipos() async {
    setState(() {
      _isLoadingEquipos = true;
      _equiposError = null;
    });

    try {
      final data = await _equiposRepository.fetchByProperty(_propertyValue);
      if (!mounted) return;
      setState(() {
        _equipos = data;
        // Pre-compute filtered lists once, not in every build
        _cachedAvailable = data
            .where((e) => e.status.trim().toLowerCase() == 'disponible')
            .toList(growable: false);
        _cachedUpcoming = data
            .where((e) => e.status.trim().toLowerCase() != 'disponible')
            .toList(growable: false);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _equipos = const [];
        _cachedAvailable = const [];
        _cachedUpcoming = const [];
        _equiposError = e.toString();
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoadingEquipos = false;
      });
    }
  }

  Future<void> _loadResponsivas() async {
    final clientId = context.read<AuthProvider>().state.user?.clientId ?? 0;

    setState(() {
      _isLoadingResponsivas = true;
      _responsivasError = null;
    });

    if (clientId <= 0) {
      setState(() {
        _responsivas = const [];
        _responsivasError = 'Cliente no encontrado. Inicia sesión nuevamente.';
        _isLoadingResponsivas = false;
      });
      return;
    }

    try {
      final data = await _responsivasRepository.fetchByClient(clientId);
      if (!mounted) return;
      setState(() {
        _responsivas = data;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _responsivas = const [];
        _responsivasError = e.toString();
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoadingResponsivas = false;
      });
    }
  }

  void _showMessage(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  Future<String?> _askRequestType() async {
    return showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      builder: (sheetContext) {
        final scheme = Theme.of(sheetContext).colorScheme;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '¿Qué necesitas?',
                  style: Theme.of(sheetContext)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 6),
                Text(
                  'Elige si deseas una cotización para renta o venta.',
                  style: Theme.of(sheetContext)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
                const SizedBox(height: 12),
                _RequestTypeTile(
                  label: 'Renta',
                  icon: Icons.calendar_month_outlined,
                  color: scheme.primary,
                  onTap: () => Navigator.of(sheetContext).pop('Renta'),
                ),
                const SizedBox(height: 8),
                _RequestTypeTile(
                  label: 'Venta',
                  icon: Icons.sell_outlined,
                  color: scheme.secondary,
                  onTap: () => Navigator.of(sheetContext).pop('Venta'),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  String _buildServiceName(Equipo equipo) {
    final parts = [
      equipo.brand.name,
      equipo.model,
      if (equipo.economicNumber.trim().isNotEmpty) 'N. Económico ${equipo.economicNumber}',
      if (equipo.serialNumber.trim().isNotEmpty) 'Serie ${equipo.serialNumber}',
    ];
    final description = parts.where((p) => p.trim().isNotEmpty).join(' · ');
    return description.isEmpty ? 'Equipo sin descripción' : description;
  }

  Future<void> _handleRequest(Equipo equipo) async {
    final user = context.read<AuthProvider>().state.user;
    if (user == null) {
      _showMessage('Inicia sesión para enviar una solicitud.');
      return;
    }

    if (user.clientId <= 0 || equipo.id <= 0) {
      _showMessage('Cliente o equipo no válidos para la solicitud.');
      return;
    }

    final requestType = await _askRequestType();
    if (requestType == null) return;

    if (!mounted) return;
    setState(() {
      _submittingEquipmentId = equipo.id;
      _submittingRequestType = requestType;
    });

    try {
      final serviceName = _buildServiceName(equipo);
      await _serviceRequestsRepository.createRequest(
        clientId: user.clientId,
        equipmentId: equipo.id,
        appUserId: user.id,
        serviceName: serviceName,
        requestType: requestType,
        status: 'Abierta',
      );
      if (!mounted) return;
      _showMessage('Solicitud $requestType enviada para ${equipo.brand.name} ${equipo.model}.');
    } catch (e) {
      if (!mounted) return;
      _showMessage(e.toString());
    } finally {
      if (!mounted) return;
      setState(() {
        _submittingEquipmentId = null;
        _submittingRequestType = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Rentas'),
        ),
        body: Column(
          children: [
            Container(
              color: Colors.white,
              child: TabBar(
                indicatorColor: Theme.of(context).colorScheme.primary,
                labelColor: Theme.of(context).colorScheme.primary,
                unselectedLabelColor: Colors.grey.shade300,
                tabs: const [
                  Tab(text: 'Disponible'),
                  Tab(text: 'Próximamente'),
                  Tab(text: 'Responsivas'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildEquiposTab(available: true),
                  _buildEquiposTab(available: false),
                  _buildResponsivasTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEquiposTab({required bool available}) {
    if (_isLoadingEquipos) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_equiposError != null) {
      return _ErrorRetryView(
        message: _equiposError!,
        onRetry: _loadEquipos,
      );
    }

    final equipos = available ? _cachedAvailable : _cachedUpcoming;

    if (equipos.isEmpty) {
      return _EmptyStateView(
        title: available ? 'Sin equipos disponibles' : 'Sin equipos próximos',
        message: available
            ? 'No hay equipos en estado Disponible para la propiedad.'
            : 'No hay equipos marcados como Próximamente.',
        onRefresh: _loadEquipos,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadEquipos,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: equipos.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final equipo = equipos[index];
          final isSubmitting = _submittingEquipmentId == equipo.id;
          return RepaintBoundary(
            child: _RentalEquipmentCard(
              equipo: equipo,
              available: available,
              isSubmitting: isSubmitting,
              submittingLabel: _submittingRequestType,
              onAction: () {
                _handleRequest(equipo);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildResponsivasTab() {
    if (_isLoadingResponsivas) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_responsivasError != null) {
      return _ErrorRetryView(
        message: _responsivasError!,
        onRetry: _loadResponsivas,
      );
    }

    if (_responsivas.isEmpty) {
      return _EmptyStateView(
        title: 'Sin responsivas',
        message: 'No hay historiales disponibles para tu cuenta.',
        onRefresh: _loadResponsivas,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadResponsivas,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _responsivas.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final record = _responsivas[index];
          return RepaintBoundary(
            child: _ResponsivaCard(
              record: record,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ReporteScreen(
                      reportUrl:
                          'https://ddg.com.mx/dashboard/focr02/${record.id}/reporte',
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _RentalEquipmentCard extends StatelessWidget {
  const _RentalEquipmentCard({
    required this.equipo,
    required this.available,
    required this.isSubmitting,
    required this.submittingLabel,
    required this.onAction,
  });

  final Equipo equipo;
  final bool available;
  final bool isSubmitting;
  final String? submittingLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final status = equipo.status.trim().isEmpty ? 'Rentado' : equipo.status;
    final statusColor = available ? scheme.primary : scheme.tertiary;
    final actionLabel = available ? 'Cotizar' : 'Solicitar información';
    final actionIcon = available ? Icons.request_quote_outlined : Icons.info_outline;
    final imageUrl = equipo.brandImageUrl;
    final buttonLabel = isSubmitting ? (submittingLabel ?? 'Enviando...') : actionLabel;
    final placeholder = Container(
      width: 96,
      height: 90,
      color: Colors.grey.shade200,
      alignment: Alignment.center,
      child: Icon(Icons.image_outlined, color: Colors.grey.shade500),
    );

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    width: 96,
                    height: 90,
                    child: imageUrl == null
                        ? placeholder
                        : Image.network(
                            imageUrl,
                            fit: BoxFit.contain,
                            cacheWidth: 192, // 96 * 2 for high DPI screens
                            errorBuilder: (_, __, ___) => placeholder,
                            loadingBuilder: (context, child, progress) {
                              if (progress == null) return child;
                              final expected = progress.expectedTotalBytes;
                              final loaded = progress.cumulativeBytesLoaded;
                              return Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  value: expected != null ? loaded / (expected == 0 ? 1 : expected) : null,
                                ),
                              );
                            },
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${equipo.brand.name} · ${equipo.model}',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      _LabeledValue(label: 'Tipo', value: equipo.type.name),
                      _LabeledValue(
                        label: 'N. Económico',
                        value: equipo.economicNumber,
                      ),
                      _LabeledValue(
                        label: 'Serie',
                        value: equipo.serialNumber,
                      ),
                      _LabeledValue(
                        label: 'Capacidad',
                        value: equipo.capacity,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _StatusPill(label: status, color: statusColor),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Propiedad: ${equipo.property}',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: isSubmitting ? null : onAction,
                  icon: isSubmitting
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(scheme.onPrimary),
                          ),
                        )
                      : Icon(actionIcon, size: 18),
                  label: Text(buttonLabel),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: statusColor,
                    foregroundColor: scheme.onPrimary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RequestTypeTile extends StatelessWidget {
  const _RequestTypeTile({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: scheme.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label == 'Renta'
                        ? 'Solicita una cotización para renta.'
                        : 'Solicita información para compra / venta.',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }
}

class _ResponsivaCard extends StatelessWidget {
  const _ResponsivaCard({required this.record, this.onTap});

  final ResponsivaRecord record;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final statusColor = _statusColor(record.status, scheme);
    final equipmentTitle = _buildEquipmentTitle(record);
    final date = _formatDate(record.dateCreated);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      equipmentTitle,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  _StatusPill(label: record.status, color: statusColor),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 6,
                children: [
                  _ChipLabel(
                    icon: Icons.receipt_long_outlined,
                    text: record.fileId == null || record.fileId!.isEmpty
                        ? 'Sin FILE'
                        : 'FILE ${record.fileId}',
                  ),
                  _ChipLabel(
                    icon: Icons.event_outlined,
                    text: 'Creado: $date',
                  ),
                  if (record.employeeName != null)
                    _ChipLabel(
                      icon: Icons.engineering_outlined,
                      text: 'Técnico: ${record.employeeName}',
                    ),
                ],
              ),
              if (record.clientName != null || record.receptionName != null)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Row(
                    children: [
                      if (record.clientName != null)
                        Expanded(
                          child: _LabeledValue(
                            label: 'Cliente',
                            value: record.clientName!,
                          ),
                        ),
                      if (record.receptionName != null) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: _LabeledValue(
                            label: 'Recibió',
                            value: record.receptionName!,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onTap,
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  label: const Text('Ver PDF'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _buildEquipmentTitle(ResponsivaRecord record) {
    final brand = record.equipmentBrand ?? '';
    final model = record.equipmentModel ?? '';
    final economic = record.equipmentEconomicNumber ?? '';
    final pieces = [brand, model, economic].where((s) => s.trim().isNotEmpty);
    return pieces.isEmpty ? 'Equipo sin descripción' : pieces.join(' · ');
  }

  static String _formatDate(DateTime? value) {
    if (value == null) return '—';
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(value.day)}/${two(value.month)}/${value.year}';
  }

  static Color _statusColor(String raw, ColorScheme scheme) {
    final s = raw.trim().toLowerCase();
    if (s.contains('firm') || s.contains('signed')) return scheme.secondary;
    if (s.contains('abierto') || s.contains('open')) return scheme.primary;
    return scheme.tertiary;
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final text = label.trim().isEmpty ? '—' : label;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: Theme.of(context)
            .textTheme
            .labelMedium
            ?.copyWith(color: color, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _LabeledValue extends StatelessWidget {
  const _LabeledValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context)
              .textTheme
              .labelMedium
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 2),
        Text(
          value.isEmpty ? '—' : value,
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _ChipLabel extends StatelessWidget {
  const _ChipLabel({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: scheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(
            text,
            style: Theme.of(context)
                .textTheme
                .labelLarge
                ?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _EmptyStateView extends StatelessWidget {
  const _EmptyStateView({
    required this.title,
    required this.message,
    required this.onRefresh,
  });

  final String title;
  final String message;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(32),
        children: [
          const SizedBox(height: 40),
          Icon(Icons.inbox_outlined, size: 56, color: scheme.onSurfaceVariant),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _ErrorRetryView extends StatelessWidget {
  const _ErrorRetryView({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'No se pudo cargar la información',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.red),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
