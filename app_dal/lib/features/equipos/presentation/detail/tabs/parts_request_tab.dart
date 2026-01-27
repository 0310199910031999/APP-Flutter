import 'package:app_dal/features/auth/providers/auth_provider.dart';
import 'package:app_dal/features/equipos/models/equipo.dart';
import 'package:app_dal/features/equipos/models/service_request_record.dart';
import 'package:app_dal/features/equipos/models/spare_part.dart';
import 'package:app_dal/features/equipos/models/spare_part_category.dart';
import 'package:app_dal/features/equipos/presentation/detail/widgets/empty_state_card.dart';
import 'package:app_dal/features/equipos/presentation/detail/widgets/error_view.dart';
import 'package:app_dal/features/equipos/repositories/service_requests_repository.dart';
import 'package:app_dal/features/equipos/repositories/spare_parts_repository.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PartsRequestTab extends StatefulWidget {
  const PartsRequestTab({
    super.key,
    required this.equipo,
    required this.onRefreshEquipo,
  });

  final Equipo equipo;
  final Future<void> Function() onRefreshEquipo;

  @override
  State<PartsRequestTab> createState() => _PartsRequestTabState();
}

class _PartsRequestTabState extends State<PartsRequestTab>
    with AutomaticKeepAliveClientMixin {
  final _requestsRepository = ServiceRequestsRepository();
  final _spareRepository = SparePartsRepository();

  late Future<List<SparePartCategory>> _categoriesFuture;
  late Future<List<SparePart>> _partsFuture;
  late Future<List<ServiceRequestRecord>> _recordsFuture;

  int? _selectedCategoryId;
  int? _submittingPartId;
  String? _submittingRequestType;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _categoriesFuture = _spareRepository.fetchCategories();
    _partsFuture = _spareRepository.fetchSpareParts();
    _recordsFuture =
      _requestsRepository.fetchSparePartRequestsByEquipmentId(widget.equipo.id);
  }

  @override
  void didUpdateWidget(covariant PartsRequestTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.equipo.id != widget.equipo.id) {
      _categoriesFuture = _spareRepository.fetchCategories();
      _partsFuture = _spareRepository.fetchSpareParts();
      _recordsFuture =
          _requestsRepository.fetchSparePartRequestsByEquipmentId(widget.equipo.id);
      _selectedCategoryId = null;
      _searchController.clear();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    await widget.onRefreshEquipo();
    setState(() {
      _categoriesFuture = _spareRepository.fetchCategories();
      _partsFuture = _spareRepository.fetchSpareParts();
      _recordsFuture =
          _requestsRepository.fetchSparePartRequestsByEquipmentId(widget.equipo.id);
    });
    await Future.wait([_categoriesFuture, _partsFuture, _recordsFuture]);
  }

  List<SparePart> _partsByCategory(List<SparePart> parts, int categoryId) {
    return parts
        .where((p) => p.categoryId == categoryId)
        .toList(growable: false);
  }

  List<SparePart> _filterParts(
    List<SparePart> parts,
    int categoryId,
    String search,
  ) {
    final byCategory = _partsByCategory(parts, categoryId);
    if (search.trim().isEmpty) return byCategory;
    final query = search.toLowerCase();
    return byCategory
        .where((p) => p.description.toLowerCase().contains(query))
        .toList(growable: false);
  }

  Future<void> _handleRequest(
    SparePart part,
    String requestType,
    {VoidCallback? onCompleted,}
  ) async {
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
      _submittingPartId = part.id;
      _submittingRequestType = requestType;
    });

    try {
      await _requestsRepository.createRequest(
        clientId: user.clientId,
        equipmentId: widget.equipo.id,
        appUserId: user.id,
        sparePartId: part.id,
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
              'Solicitud ${requestType.toLowerCase()} enviada para ${part.description}',
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
          _submittingPartId = null;
          _submittingRequestType = null;
        });
      }
    }
  }

  Future<void> _openRequestSheet(
    List<SparePartCategory> categories,
    List<SparePart> parts,
  ) async {
    if (categories.isEmpty || parts.isEmpty) return;
    final rootContext = context;
    int localCategoryId = _resolveCategory(categories);
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
            final filteredParts = _filterParts(parts, localCategoryId, searchTerm);
            final categoryTitle = categories
                .firstWhere(
                  (c) => c.id == localCategoryId,
                  orElse: () => SparePartCategory(id: 0, description: ''),
                )
                .description;

            void goToCategories() {
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

            void goToParts(int categoryId) {
              setModalState(() {
                localCategoryId = categoryId;
                _selectedCategoryId = categoryId;
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
                        title: pageIndex == 0 ? 'Elige la categoría' : categoryTitle,
                        subtitle: pageIndex == 0
                            ? 'Paso 1/2: selecciona una categoría'
                            : 'Paso 2/2: elige la refacción y cotiza o solicita',
                        showBack: pageIndex == 1,
                        onBack: pageIndex == 1 ? goToCategories : null,
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: PageView(
                          controller: pageController,
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            _CategoryPage(
                              categories: categories,
                              selectedId: localCategoryId,
                              scrollController: pageIndex == 0 ? scrollController : null,
                              onSelect: goToParts,
                            ),
                            _PartsPage(
                              categoryName: categoryTitle,
                              parts: filteredParts,
                              isProcessingId: _submittingPartId,
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
                              onQuote: (part) => _handleRequest(
                                part,
                                'Cotizar',
                                onCompleted: () {
                                  Navigator.of(rootContext).maybePop();
                                  _showSuccessDialog(
                                    rootContext,
                                    title: 'Solicitud enviada',
                                    message: 'Cotización enviada para ${part.description}.',
                                  );
                                },
                              ),
                              onRequest: (part) => _handleRequest(
                                part,
                                'Solicitar',
                                onCompleted: () {
                                  Navigator.of(rootContext).maybePop();
                                  _showSuccessDialog(
                                    rootContext,
                                    title: 'Solicitud enviada',
                                    message: 'Solicitud enviada para ${part.description}.',
                                  );
                                },
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

  int _resolveCategory(List<SparePartCategory> categories) {
    if (categories.isEmpty) return 0;
    final current = _selectedCategoryId;
    if (current != null && categories.any((c) => c.id == current)) {
      return current;
    }
    _selectedCategoryId = categories.first.id;
    return categories.first.id;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return RefreshIndicator(
      onRefresh: _refresh,
      child: FutureBuilder<List<SparePartCategory>>(
        future: _categoriesFuture,
        builder: (context, catSnapshot) {
          final categories = catSnapshot.data ?? const <SparePartCategory>[];
          final catError = catSnapshot.hasError ? catSnapshot.error : null;

          return FutureBuilder<List<SparePart>>(
            future: _partsFuture,
            builder: (context, partsSnapshot) {
              final parts = partsSnapshot.data ?? const <SparePart>[];
              final partsError = partsSnapshot.hasError ? partsSnapshot.error : null;

              return CustomScrollView(
                key: PageStorageKey('parts-request-${widget.equipo.id}'),
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    sliver: SliverToBoxAdapter(
                      child: _HeroCard(
                        equipoName: widget.equipo.economicNumber,
                        onTap: (categories.isEmpty || parts.isEmpty)
                            ? () {
                                final msg =
                                    catError?.toString() ?? partsError?.toString() ?? 'Información no disponible. Recarga e intenta de nuevo.';
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(msg)),
                                );
                              }
                            : () => _openRequestSheet(categories, parts),
                        errorText: catError?.toString() ?? partsError?.toString(),
                        isLoading: catSnapshot.connectionState == ConnectionState.waiting ||
                            partsSnapshot.connectionState == ConnectionState.waiting,
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    sliver: SliverToBoxAdapter(
                      child: _HistoryHeader(onRefresh: _refresh, title: 'Historial de refacciones'),
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
                              message: 'Aún no hay solicitudes de refacciones para este equipo.',
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
                                child: _RecordCard(record: record, highlightCategory: _categoryNameFor(record, categories)),
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
          );
        },
      ),
    );
  }

  String _categoryNameFor(ServiceRequestRecord record, List<SparePartCategory> categories) {
    final catId = record.sparePart?.category?.id ?? record.sparePart?.categoryId ?? 0;
    final match = categories.firstWhere(
      (c) => c.id == catId,
      orElse: () => SparePartCategory(id: 0, description: ''),
    );
    return match.description;
  }

  void _showSuccessDialog(BuildContext context, {required String title, required String message}) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cerrar'),
          ),
        ],
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
              child: Icon(Icons.build_outlined, color: scheme.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Solicitud de refacciones',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Equipo ${equipoName.isEmpty ? 'sin número económico' : equipoName}.'
                    ' Elige categoría, revisa refacciones y decide entre cotizar o solicitar.',
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
  const _HistoryHeader({required this.onRefresh, required this.title});

  final Future<void> Function() onRefresh;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
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
  const _RecordCard({required this.record, this.highlightCategory = ''});

  final ServiceRequestRecord record;
  final String highlightCategory;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final statusColor = _statusColor(scheme, record.status);
    final dateText = _formatDate(record.dateCreated);
    final userText = record.appUserId == 0 ? '—' : 'Usuario ${record.appUserId}';
    final statusText = record.status.trim().isEmpty ? '—' : record.status;
    final categoryName = record.sparePart?.category?.description ?? highlightCategory;
    final partDesc = record.sparePart?.description ?? record.serviceName;
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
                    categoryName.isEmpty ? 'Refacción' : categoryName,
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
                        partDesc.isEmpty ? 'Refacción' : partDesc,
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
        labelText: 'Buscar refacción',
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

class _CategoryPage extends StatelessWidget {
  const _CategoryPage({
    required this.categories,
    required this.selectedId,
    required this.onSelect,
    this.scrollController,
  });

  final List<SparePartCategory> categories;
  final int selectedId;
  final ValueChanged<int> onSelect;
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListView.separated(
      controller: scrollController,
      padding: EdgeInsets.zero,
      itemCount: categories.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final c = categories[index];
        final isSelected = c.id == selectedId;
        return ListTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            tileColor: isSelected
              ? scheme.primary.withValues(alpha: 0.12)
              : scheme.surfaceContainerHighest.withValues(alpha: 0.4),
          title: Text(
            c.description,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: isSelected ? scheme.primary : scheme.onSurface,
                ),
          ),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () => onSelect(c.id),
        );
      },
    );
  }
}

class _PartsPage extends StatelessWidget {
  const _PartsPage({
    required this.categoryName,
    required this.parts,
    required this.onQuote,
    required this.onRequest,
    required this.searchField,
    this.scrollController,
    this.isProcessingId,
    this.processingLabel,
  });

  final String categoryName;
  final List<SparePart> parts;
  final void Function(SparePart) onQuote;
  final void Function(SparePart) onRequest;
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
              label: Text(categoryName.isEmpty ? 'Refacciones' : categoryName),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
        const SizedBox(height: 8),
        searchField,
        const SizedBox(height: 12),
        Expanded(
          child: parts.isEmpty
              ? ListView(
                  controller: scrollController,
                  children: const [
                    EmptyStateCard(
                      icon: Icons.inventory_2_outlined,
                      title: 'Sin refacciones en esta categoría',
                      message: 'Prueba otra categoría o vuelve a intentar más tarde.',
                    ),
                  ],
                )
              : ListView.separated(
                  controller: scrollController,
                  itemCount: parts.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final part = parts[index];
                    return _SparePartCard(
                      part: part,
                      category: part.category ?? SparePartCategory(id: part.categoryId, description: categoryName),
                      isProcessing: isProcessingId == part.id,
                      processingLabel: processingLabel,
                      onQuote: () => onQuote(part),
                      onRequest: () => onRequest(part),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _SparePartCard extends StatelessWidget {
  const _SparePartCard({
    required this.part,
    required this.category,
    required this.onQuote,
    required this.onRequest,
    this.isProcessing = false,
    this.processingLabel,
  });

  final SparePart part;
  final SparePartCategory category;
  final VoidCallback onQuote;
  final VoidCallback onRequest;
  final bool isProcessing;
  final String? processingLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isQuoteLoading = isProcessing && (processingLabel?.toLowerCase() == 'cotizar');
    final isRequestLoading = isProcessing && (processingLabel?.toLowerCase() == 'solicitar');

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
                    category.description.isEmpty ? 'Refacción' : category.description,
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
                        part.description,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                ),
              ],
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
