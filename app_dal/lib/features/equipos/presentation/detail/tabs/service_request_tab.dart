import 'package:app_dal/features/auth/providers/auth_provider.dart';
import 'package:app_dal/features/equipos/models/equipo.dart';
import 'package:app_dal/features/equipos/models/service_option.dart';
import 'package:app_dal/features/equipos/models/service_request_record.dart';
import 'package:app_dal/features/equipos/presentation/detail/widgets/empty_state_card.dart';
import 'package:app_dal/features/equipos/presentation/detail/widgets/error_view.dart';
import 'package:app_dal/features/equipos/repositories/service_requests_repository.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ServiceRequestTab extends StatefulWidget {
  const ServiceRequestTab({
    super.key,
    required this.equipo,
    required this.onRefreshEquipo,
  });

  final Equipo equipo;
  final Future<void> Function() onRefreshEquipo;

  @override
  State<ServiceRequestTab> createState() => _ServiceRequestTabState();
}

class _ServiceRequestTabState extends State<ServiceRequestTab>
    with AutomaticKeepAliveClientMixin {
  final _repository = ServiceRequestsRepository();
  late Future<List<ServiceOption>> _servicesFuture;
  late Future<List<ServiceRequestRecord>> _recordsFuture;
  String? _selectedType;
  int? _submittingServiceId;
  String? _submittingRequestType;

  @override
  void initState() {
    super.initState();
    _servicesFuture = _repository.fetchServices();
    _recordsFuture =
        _repository.fetchServiceRequestsByEquipmentId(widget.equipo.id);
  }

  @override
  void didUpdateWidget(covariant ServiceRequestTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.equipo.id != widget.equipo.id) {
      _servicesFuture = _repository.fetchServices();
      _recordsFuture =
          _repository.fetchServiceRequestsByEquipmentId(widget.equipo.id);
    }
  }

  Future<void> _refresh() async {
    await widget.onRefreshEquipo();
    setState(() {
      _servicesFuture = _repository.fetchServices();
      _recordsFuture =
          _repository.fetchServiceRequestsByEquipmentId(widget.equipo.id);
    });
    await Future.wait([_servicesFuture, _recordsFuture]);
  }

  List<String> _typesFrom(List<ServiceOption> services) {
    final set = <String>{};
    for (final s in services) {
      final t = s.type.trim();
      if (t.isNotEmpty) set.add(t);
    }
    final list = set.toList();
    list.sort((a, b) {
      const priority = ['Preventivo', 'Correctivo', 'Otros Servicios'];
      final ia = priority.indexWhere((p) => p.toLowerCase() == a.toLowerCase());
      final ib = priority.indexWhere((p) => p.toLowerCase() == b.toLowerCase());
      if (ia == -1 && ib == -1) return a.compareTo(b);
      if (ia == -1) return 1;
      if (ib == -1) return -1;
      return ia.compareTo(ib);
    });
    return list;
  }

  String _resolveSelectedType(List<String> types) {
    if (types.isEmpty) return '';
    final current = _selectedType;
    if (current != null &&
        types.any((t) => t.toLowerCase() == current.toLowerCase())) {
      return types.firstWhere(
        (t) => t.toLowerCase() == current.toLowerCase(),
        orElse: () => types.first,
      );
    }
    const defaultOrder = ['Preventivo', 'Correctivo', 'Otros Servicios'];
    for (final desired in defaultOrder) {
      final match = types.firstWhere(
        (t) => t.toLowerCase() == desired.toLowerCase(),
        orElse: () => '',
      );
      if (match.isNotEmpty) {
        _selectedType = match;
        return match;
      }
    }
    _selectedType = types.first;
    return types.first;
  }

  List<ServiceOption> _filterByType(
    List<ServiceOption> services,
    String type,
  ) {
    final normalized = type.toLowerCase();
    return services
        .where((s) => s.type.toLowerCase() == normalized)
        .toList(growable: false);
  }

  Future<void> _handleRequest(
    ServiceOption service,
    String requestType, {
    VoidCallback? onCompleted,
  }) async {
    final user = context.read<AuthProvider>().state.user;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo obtener el usuario actual')),
      );
      return;
    }

    if (user.clientId <= 0 || widget.equipo.id <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cliente o equipo no válidos para la solicitud'),
        ),
      );
      return;
    }

    setState(() {
      _submittingServiceId = service.id;
      _submittingRequestType = requestType;
    });

    try {
      await _repository.createRequest(
        clientId: user.clientId,
        equipmentId: widget.equipo.id,
        appUserId: user.id,
        serviceId: service.id,
        requestType: requestType,
      );
      if (!mounted) return;
      onCompleted?.call();
      await _refresh();
      if (!mounted) return;
      if (onCompleted == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Solicitud ${requestType.toLowerCase()} enviada para ${service.name}',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) {
        setState(() {
          _submittingServiceId = null;
          _submittingRequestType = null;
        });
      }
    }
  }

  Future<void> _openRequestSheet(List<ServiceOption> services) async {
    if (services.isEmpty) return;
    final types = _typesFrom(services);
    if (types.isEmpty) return;
    String localSelected = _resolveSelectedType(types);
    final rootContext = context;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final filtered = _filterByType(services, localSelected);

            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.82,
              minChildSize: 0.6,
              maxChildSize: 0.95,
              builder: (context, scrollController) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 4,
                        width: 48,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.outlineVariant,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      Text(
                        'Nueva solicitud',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '1. Elige el tipo de servicio\n2. Selecciona entre solicitar o cotizar',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(height: 16),
                      _TypeSelector(
                        types: types,
                        selected: localSelected,
                        onSelected: (value) {
                          setModalState(() {
                            localSelected = value;
                          });
                          setState(() {
                            _selectedType = value;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: filtered.isEmpty
                            ? ListView(
                                controller: scrollController,
                                children: const [
                                  EmptyStateCard(
                                    icon: Icons.handyman_outlined,
                                    title: 'Sin servicios en esta categoría',
                                    message:
                                        'Selecciona otra categoría o vuelve a intentar más tarde.',
                                  ),
                                ],
                              )
                            : ListView.separated(
                                controller: scrollController,
                                itemCount: filtered.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 10),
                                itemBuilder: (context, index) {
                                  final service = filtered[index];
                                  return _ServiceCard(
                                    service: service,
                                    isProcessing:
                                        _submittingServiceId == service.id,
                                    processingLabel: _submittingRequestType,
                                    onQuote: () => _handleRequest(
                                      service,
                                      'Cotizar',
                                      onCompleted: () {
                                        Navigator.of(rootContext).maybePop();
                                        showDialog<void>(
                                          context: rootContext,
                                          builder: (ctx) {
                                            return AlertDialog(
                                              title: const Text('Solicitud enviada'),
                                              content: Text(
                                                'Cotización enviada para ${service.name}.',
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.of(ctx).pop(),
                                                  child: const Text('Cerrar'),
                                                ),
                                              ],
                                            );
                                          },
                                        );
                                      },
                                    ),
                                    onRequest: () => _handleRequest(
                                      service,
                                      'Solicitar',
                                      onCompleted: () {
                                        Navigator.of(rootContext).maybePop();
                                        showDialog<void>(
                                          context: rootContext,
                                          builder: (ctx) {
                                            return AlertDialog(
                                              title: const Text('Solicitud enviada'),
                                              content: Text(
                                                'Solicitud enviada para ${service.name}.',
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.of(ctx).pop(),
                                                  child: const Text('Cerrar'),
                                                ),
                                              ],
                                            );
                                          },
                                        );
                                      },
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return RefreshIndicator(
      onRefresh: _refresh,
      child: FutureBuilder<List<ServiceOption>>(
        future: _servicesFuture,
        builder: (context, servicesSnapshot) {
          final services = servicesSnapshot.data ?? const <ServiceOption>[];
          final servicesError = servicesSnapshot.hasError ? servicesSnapshot.error : null;

          return CustomScrollView(
            key: PageStorageKey('service-request-${widget.equipo.id}'),
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                sliver: SliverToBoxAdapter(
                  child: _HeroCard(
                    equipoName: widget.equipo.economicNumber,
                    onTap: services.isEmpty
                        ? () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  servicesError?.toString() ??
                                      'Servicios no disponibles. Intenta recargar.',
                                ),
                              ),
                            );
                          }
                        : () => _openRequestSheet(services),
                    errorText: servicesError?.toString(),
                    isLoading: servicesSnapshot.connectionState == ConnectionState.waiting,
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                sliver: SliverToBoxAdapter(
                  child: _HistoryHeader(onRefresh: _refresh),
                ),
              ),
              FutureBuilder<List<ServiceRequestRecord>>(
                future: _recordsFuture,
                builder: (context, recordSnapshot) {
                  if (recordSnapshot.connectionState == ConnectionState.waiting) {
                    return const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    );
                  }

                  if (recordSnapshot.hasError) {
                    return SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: ErrorView(
                          title: 'No se pudo cargar el historial',
                          message: recordSnapshot.error.toString(),
                          onRetry: _refresh,
                        ),
                      ),
                    );
                  }

                      final records =
                        recordSnapshot.data ?? const <ServiceRequestRecord>[];

                  if (records.isEmpty) {
                    return const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(16, 0, 16, 32),
                        child: EmptyStateCard(
                          icon: Icons.history,
                          title: 'Sin solicitudes registradas',
                          message: 'Aún no hay solicitudes para este equipo.',
                        ),
                      ),
                    );
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final record = records[index];
                          return Padding(
                            padding: EdgeInsets.only(
                              bottom: index == records.length - 1 ? 0 : 10,
                            ),
                            child: _RecordCard(record: record),
                          );
                        },
                        childCount: records.length,
                      ),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.equipoName,
    required this.onTap,
    this.errorText,
    this.isLoading = false,
  });

  final String equipoName;
  final VoidCallback onTap;
  final String? errorText;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              scheme.primary.withValues(alpha: 0.16),
              scheme.surface,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(Icons.handyman_outlined, color: scheme.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Solicitud de servicio',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Equipo ${equipoName.isEmpty ? 'sin número económico' : equipoName}.'
                    ' Elige el tipo de servicio, revisa opciones y decide entre cotizar o solicitar.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                  if (errorText != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      errorText!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.error,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      FilledButton.icon(
                        onPressed: isLoading ? null : onTap,
                        icon: const Icon(Icons.add_circle_outline),
                        label: Text(isLoading ? 'Cargando…' : 'Nueva solicitud'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryHeader extends StatelessWidget {
  const _HistoryHeader({required this.onRefresh});

  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          'Historial de solicitudes',
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w900),
        ),
        const Spacer(),
        IconButton(
          tooltip: 'Recargar historial',
          onPressed: () => onRefresh(),
          icon: const Icon(Icons.refresh),
        ),
      ],
    );
  }
}

class _RecordCard extends StatelessWidget {
  const _RecordCard({required this.record});

  final ServiceRequestRecord record;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final statusColor = _statusColor(scheme, record.status);
    final dateText = _formatDate(record.dateCreated);
    final userText = record.appUserId == 0 ? '—' : 'Usuario ${record.appUserId}';
    final statusText = record.status.trim().isEmpty ? '—' : record.status;
    final serviceCode = (record.service?.code ?? '').trim().isNotEmpty
        ? record.service!.code
        : record.serviceName;
    final serviceName = (record.service?.name ?? '').trim().isNotEmpty
        ? record.service!.name
        : record.serviceName;
    final description = (record.service?.description ?? '').trim();
    final requestType = record.requestType.trim();

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    serviceCode,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: scheme.primary,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        serviceName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    statusText,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (description != null && description.isNotEmpty) ...[
              Text(
                description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 8),
            ],
            Row(
              children: [
                Expanded(
                  child: _LabeledValue(
                    label: 'Usuario',
                    value: userText,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _LabeledValue(
                    label: 'Fecha',
                    value: dateText,
                    alignEnd: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Chip(
                  label: Text(requestType.isEmpty ? 'Tipo no definido' : requestType),
                  visualDensity: VisualDensity.compact,
                  labelStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(width: 8),
                if (record.dateClosed != null)
                  Chip(
                    label: Text('Cerrado: ${_formatDate(record.dateClosed)}'),
                    visualDensity: VisualDensity.compact,
                    labelStyle: Theme.of(context).textTheme.labelMedium,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static Color _statusColor(ColorScheme scheme, String? status) {
    final s = (status ?? '').trim().toLowerCase();
    if (s.contains('abierto') || s.contains('open')) return scheme.primary;
    if (s.contains('cerrado') || s.contains('closed')) return scheme.secondary;
    return scheme.primary;
  }

  static String _formatDate(DateTime? value) {
    if (value == null) return '—';
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(value.day)}/${two(value.month)}/${value.year}';
  }
}

class _LabeledValue extends StatelessWidget {
  const _LabeledValue({required this.label, required this.value, this.alignEnd = false});

  final String label;
  final String value;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final display = value.trim().isEmpty ? '—' : value;
    return Column(
      crossAxisAlignment: alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 2),
        Text(
          display,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
      ],
    );
  }
}

class _TypeSelector extends StatelessWidget {
  const _TypeSelector({
    required this.types,
    required this.selected,
    required this.onSelected,
  });

  final List<String> types;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    if (types.isEmpty) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tipo de servicio',
          style: Theme.of(context)
              .textTheme
              .titleSmall
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: types.map((t) {
            final isSelected = t.toLowerCase() == selected.toLowerCase();
            return ChoiceChip(
              label: Text(t),
              selected: isSelected,
              onSelected: (_) => onSelected(t),
              selectedColor: scheme.primary.withValues(alpha: 0.12),
              labelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isSelected ? scheme.primary : scheme.onSurface,
                    fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                  ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({
    required this.service,
    required this.onQuote,
    required this.onRequest,
    this.isProcessing = false,
    this.processingLabel,
  });

  final ServiceOption service;
  final VoidCallback onQuote;
  final VoidCallback onRequest;
  final bool isProcessing;
  final String? processingLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final description = service.description ?? 'Sin descripción disponible';
    final isQuoteLoading =
        isProcessing && (processingLabel?.toLowerCase() == 'cotizar');
    final isRequestLoading =
        isProcessing && (processingLabel?.toLowerCase() == 'solicitar');

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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    service.code,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: scheme.primary,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        service.name,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: scheme.secondary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    service.type,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: scheme.secondary,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: isProcessing ? null : onQuote,
                    icon: isQuoteLoading
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: scheme.primary,
                            ),
                          )
                        : const Icon(Icons.request_quote_outlined),
                    label: Text(isQuoteLoading ? 'Enviando…' : 'Cotizar'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: isProcessing ? null : onRequest,
                    icon: isRequestLoading
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: scheme.onPrimary,
                            ),
                          )
                        : const Icon(Icons.check_circle_outline),
                    label: Text(isRequestLoading ? 'Enviando…' : 'Solicitar'),
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
