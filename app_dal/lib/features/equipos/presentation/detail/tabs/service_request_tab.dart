import 'package:app_dal/features/auth/providers/auth_provider.dart';
import 'package:app_dal/features/auth/models/auth_state.dart' show User;
import 'package:app_dal/features/equipos/models/equipo.dart';
import 'package:app_dal/features/equipos/models/service_option.dart';
import 'package:app_dal/features/equipos/models/service_request_record.dart';
import 'package:app_dal/features/equipos/presentation/detail/widgets/empty_state_card.dart';
import 'package:app_dal/features/equipos/presentation/detail/widgets/error_view.dart';
import 'package:app_dal/features/equipos/repositories/service_requests_repository.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Wrapper para mantener estado de expansión de tipos de servicio
class ServiceTypeItem {
  ServiceTypeItem({
    required this.type,
    required this.services,
  });

  final String type;
  final List<ServiceOption> services;
}

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
  List<ServiceTypeItem> _cachedItems = const [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _servicesFuture = _repository.fetchServices();
    _recordsFuture =
        _repository.fetchServiceRequestsByEquipmentId(widget.equipo.id);
    _hydrateCachedItems();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ServiceRequestTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.equipo.id != widget.equipo.id) {
      _servicesFuture = _repository.fetchServices();
      _recordsFuture =
          _repository.fetchServiceRequestsByEquipmentId(widget.equipo.id);
      _hydrateCachedItems();
    }
  }

  Future<void> _refresh() async {
    await widget.onRefreshEquipo();
    setState(() {
      _servicesFuture = _repository.fetchServices();
      _recordsFuture =
          _repository.fetchServiceRequestsByEquipmentId(widget.equipo.id);
    });
    try {
      final services = await _servicesFuture;
      await _recordsFuture;
      if (!mounted) return;
      setState(() {
        _cachedItems = _buildServiceTypeItems(services);
      });
    } catch (_) {
      // El FutureBuilder mostrará el error; evitamos jank.
    }
  }

  List<ServiceTypeItem> _buildServiceTypeItems(List<ServiceOption> services) {
    final Map<String, List<ServiceOption>> groupedServices = {};
    for (final service in services) {
      final type = service.type.trim();
      if (type.isNotEmpty) {
        (groupedServices[type] ??= []).add(service);
      }
    }

    final sortedTypes = groupedServices.keys.toList();
    sortedTypes.sort((a, b) {
      const priority = ['Preventivo', 'Correctivo', 'Otros Servicios'];
      final ia = priority.indexWhere((p) => p.toLowerCase() == a.toLowerCase());
      final ib = priority.indexWhere((p) => p.toLowerCase() == b.toLowerCase());
      if (ia == -1 && ib == -1) return a.compareTo(b);
      if (ia == -1) return 1;
      if (ib == -1) return -1;
      return ia.compareTo(ib);
    });

    return sortedTypes
        .map((type) => ServiceTypeItem(
              type: type,
              services: groupedServices[type]!,
            ))
        .toList(growable: false);
  }

  Future<void> _hydrateCachedItems() async {
    try {
      final services = await _servicesFuture;
      if (!mounted) return;
      setState(() {
        _cachedItems = _buildServiceTypeItems(services);
        _selectedType = _cachedItems.isNotEmpty ? _cachedItems.first.type : null;
      });
    } catch (_) {
      // El FutureBuilder manejará el error.
    }
  }

  String _resolveServiceType(List<ServiceTypeItem> items) {
    if (items.isEmpty) return '';
    final current = _selectedType;
    if (current != null && items.any((i) => i.type == current)) {
      return current;
    }
    _selectedType = items.first.type;
    return _selectedType!;
  }

  List<ServiceOption> _filterServices(
    List<ServiceOption> services,
    String search,
  ) {
    if (search.trim().isEmpty) return services;
    final query = search.toLowerCase();
    return services
        .where(
          (s) => s.name.toLowerCase().contains(query) ||
              (s.description ?? '').toLowerCase().contains(query) ||
              s.code.toLowerCase().contains(query),
        )
        .toList(growable: false);
  }

  Future<void> _handleRequest(
    ServiceOption service,
    String requestType,
    User? currentUser, {
    VoidCallback? onCompleted,
  }) async {
    final user = currentUser;
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

    if (_cachedItems.isEmpty) return;

    final currentUser = context.read<AuthProvider>().state.user;
    String localType = _resolveServiceType(_cachedItems);
    String searchTerm = '';
    _searchController.clear();
    int pageIndex = 0;
    final pageController = PageController(initialPage: 0);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final selectedItem = _cachedItems.firstWhere(
              (i) => i.type == localType,
              orElse: () => _cachedItems.first,
            );
            final filteredServices = _filterServices(selectedItem.services, searchTerm);

            void goToTypes() {
              setModalState(() {
                pageIndex = 0;
                searchTerm = '';
                _searchController.clear();
              });
              pageController.animateToPage(
                0,
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
              );
            }

            void goToServices(String type) {
              setModalState(() {
                localType = type;
                _selectedType = type;
                searchTerm = '';
                _searchController.clear();
                pageIndex = 1;
              });
              pageController.animateToPage(
                1,
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOut,
              );
            }

            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.82,
              minChildSize: 0.6,
              maxChildSize: 0.95,
              builder: (context, scrollController) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: Column(
                    children: [
                      _SheetTopBar(
                        title: pageIndex == 0
                            ? 'Elige el tipo de servicio'
                            : selectedItem.type,
                        subtitle: pageIndex == 0
                            ? 'Paso 1/2: selecciona el tipo'
                            : 'Paso 2/2: elige el servicio y cotiza o solicita',
                        showBack: pageIndex == 1,
                        onBack: pageIndex == 1 ? goToTypes : null,
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: PageView(
                          controller: pageController,
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            _ServiceTypePage(
                              types: _cachedItems,
                              selectedType: localType,
                              scrollController: pageIndex == 0 ? scrollController : null,
                              onSelect: goToServices,
                            ),
                            _ServicesPage(
                              typeName: selectedItem.type,
                              services: filteredServices,
                              isProcessingId: _submittingServiceId,
                              processingLabel: _submittingRequestType,
                              scrollController: pageIndex == 1 ? scrollController : null,
                              searchField: _SearchField(
                                controller: _searchController,
                                onChanged: (value) {
                                  setModalState(() {
                                    searchTerm = value;
                                  });
                                },
                              ),
                              onQuote: (service) => _handleRequest(
                                service,
                                'Cotizar',
                                currentUser,
                              ),
                              onRequest: (service) => _handleRequest(
                                service,
                                'Solicitar',
                                currentUser,
                              ),
                            ),
                          ],
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

                      final allRecords = recordSnapshot.data ?? const <ServiceRequestRecord>[];
                      final records = allRecords
                          .where((r) {
                            final type = r.requestType.trim().toLowerCase();
                            return type != 'renta' && type != 'venta';
                          })
                          .toList(growable: false);

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

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: 'Buscar servicio',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'Limpiar búsqueda',
                onPressed: () {
                  controller.clear();
                  onChanged('');
                },
                icon: const Icon(Icons.close),
              ),
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.outline.withValues(alpha: 0.4)),
        ),
      ),
    );
  }
}

class _SheetTopBar extends StatelessWidget {
  const _SheetTopBar({
    required this.title,
    required this.subtitle,
    this.showBack = false,
    this.onBack,
  });

  final String title;
  final String subtitle;
  final bool showBack;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        if (showBack)
          IconButton(
            tooltip: 'Volver a categorías',
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          ),
        if (!showBack)
          Container(
            width: 42,
            alignment: Alignment.center,
            child: Container(
              height: 4,
              width: 48,
              decoration: BoxDecoration(
                color: scheme.outlineVariant,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ServiceTypePage extends StatelessWidget {
  const _ServiceTypePage({
    required this.types,
    required this.selectedType,
    required this.onSelect,
    this.scrollController,
  });

  final List<ServiceTypeItem> types;
  final String selectedType;
  final ValueChanged<String> onSelect;
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListView.separated(
      controller: scrollController,
      padding: EdgeInsets.zero,
      itemCount: types.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = types[index];
        final isSelected = item.type == selectedType;
        return ListTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            tileColor: isSelected
              ? scheme.primary.withValues(alpha: 0.12)
              : scheme.surfaceContainerHighest.withValues(alpha: 0.4),
          title: Text(
            item.type,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: isSelected ? scheme.primary : scheme.onSurface,
                ),
          ),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () => onSelect(item.type),
        );
      },
    );
  }
}

class _ServicesPage extends StatelessWidget {
  const _ServicesPage({
    required this.typeName,
    required this.services,
    required this.onQuote,
    required this.onRequest,
    required this.searchField,
    this.scrollController,
    this.isProcessingId,
    this.processingLabel,
  });

  final String typeName;
  final List<ServiceOption> services;
  final void Function(ServiceOption) onQuote;
  final void Function(ServiceOption) onRequest;
  final Widget searchField;
  final ScrollController? scrollController;
  final int? isProcessingId;
  final String? processingLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Chip(
              label: Text(typeName.isEmpty ? 'Servicios' : typeName),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
        const SizedBox(height: 8),
        searchField,
        const SizedBox(height: 12),
        Expanded(
          child: services.isEmpty
              ? ListView(
                  controller: scrollController,
                  children: const [
                    EmptyStateCard(
                      icon: Icons.handyman_outlined,
                      title: 'Sin servicios en esta categoría',
                      message: 'Prueba otro tipo o intenta más tarde.',
                    ),
                  ],
                )
              : ListView.separated(
                  controller: scrollController,
                  itemCount: services.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final service = services[index];
                    return _ServiceCard(
                      service: service,
                      isProcessing: isProcessingId == service.id,
                      processingLabel: processingLabel,
                      onQuote: () => onQuote(service),
                      onRequest: () => onRequest(service),
                    );
                  },
                ),
        ),
      ],
    );
  }
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
            if (description.isNotEmpty) ...[
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

