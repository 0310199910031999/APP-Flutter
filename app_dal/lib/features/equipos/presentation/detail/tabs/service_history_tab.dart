import 'package:app_dal/features/equipos/models/equipo.dart';
import 'package:app_dal/features/equipos/models/service_record.dart';
import 'package:app_dal/features/equipos/presentation/detail/widgets/empty_state_card.dart';
import 'package:app_dal/features/equipos/presentation/detail/widgets/error_view.dart';
import 'package:app_dal/features/equipos/presentation/report/reporte_screen.dart';
import 'package:app_dal/features/equipos/repositories/service_records_repository.dart';
import 'package:flutter/material.dart';

class ServiceHistoryTab extends StatefulWidget {
  const ServiceHistoryTab({super.key, required this.equipo});

  final Equipo equipo;

  @override
  State<ServiceHistoryTab> createState() => _ServiceHistoryTabState();
}

class _ServiceHistoryTabState extends State<ServiceHistoryTab>
    with AutomaticKeepAliveClientMixin {
  final _repository = ServiceRecordsRepository();
  late Future<List<ServiceRecord>> _future;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  DateTimeRange? _selectedRange;
  bool _showScrollToTop = false;

  @override
  void initState() {
    super.initState();
    _future = _repository.fetchByEquipmentId(widget.equipo.id);
    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(_onScrollChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _scrollController.removeListener(_onScrollChanged);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ServiceHistoryTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.equipo.id != widget.equipo.id) {
      _future = _repository.fetchByEquipmentId(widget.equipo.id);
      _searchController.clear();
      _selectedRange = null;
    }
  }

  void _onSearchChanged() {
    setState(() {});
  }

  void _onScrollChanged() {
    if (!_scrollController.hasClients) return;
    final shouldShow = _scrollController.offset > 650;
    if (shouldShow == _showScrollToTop) return;
    setState(() {
      _showScrollToTop = shouldShow;
    });
  }

  Future<void> _scrollToTop() async {
    if (!_scrollController.hasClients) return;
    await _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final initial =
        _selectedRange ??
        DateTimeRange(
          start: DateTime(
            now.year,
            now.month,
            now.day,
          ).subtract(const Duration(days: 30)),
          end: DateTime(now.year, now.month, now.day),
        );

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020, 1, 1),
      lastDate: DateTime(now.year + 1, 12, 31),
      initialDateRange: initial,
    );
    if (picked == null) return;

    setState(() {
      _selectedRange = picked;
    });
  }

  void _clearDateRange() {
    setState(() {
      _selectedRange = null;
    });
  }

  void _clearSearch() {
    _searchController.clear();
  }

  List<ServiceRecord> _applyFilters(List<ServiceRecord> records) {
    final query = _searchController.text.trim().toLowerCase();
    final range = _selectedRange;

    final filtered = records.where((r) {
      if (range != null) {
        final created = r.dateCreated;
        if (created == null) return false;
        final start = DateTime(
          range.start.year,
          range.start.month,
          range.start.day,
        );
        final endInclusive = DateTime(
          range.end.year,
          range.end.month,
          range.end.day,
          23,
          59,
          59,
          999,
        );
        if (created.isBefore(start) || created.isAfter(endInclusive)) {
          return false;
        }
      }

      if (query.isEmpty) return true;
      final haystack = <String>[
        r.format,
        r.id.toString(),
        r.fileId ?? '',
        r.employeeName ?? '',
        r.status ?? '',
      ].join(' ').toLowerCase();
      return haystack.contains(query);
    }).toList();

    filtered.sort((a, b) {
      final ad = a.dateCreated;
      final bd = b.dateCreated;
      if (ad == null && bd == null) return 0;
      if (ad == null) return 1;
      if (bd == null) return -1;
      return bd.compareTo(ad);
    });

    return filtered;
  }

  bool _isClosed(ServiceRecord record) {
    final s = (record.status ?? '').toLowerCase();
    return s.contains('cerrado') || s.contains('closed');
  }

  Future<void> _refreshRecords() async {
    setState(() {
      _future = _repository.fetchByEquipmentId(widget.equipo.id);
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return RefreshIndicator(
      onRefresh: _refreshRecords,
      child: FutureBuilder<List<ServiceRecord>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return ErrorView(
              title: 'No se pudo cargar el historial',
              message: snapshot.error.toString(),
              onRetry: _refreshRecords,
            );
          }
          final records = snapshot.data ?? const <ServiceRecord>[];
          final filtered = _applyFilters(records);

          // Pinned header has fixed height; keep it above the filter card's intrinsic height.
          final headerExtent = _selectedRange == null ? 100.0 : 128.0;

          return Stack(
            children: [
              CustomScrollView(
                key: PageStorageKey('service-history-${widget.equipo.id}'),
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _StickyHeaderDelegate(
                      minHeight: headerExtent,
                      maxHeight: headerExtent,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
                        child: _ServiceHistoryFilters(
                          searchController: _searchController,
                          selectedRange: _selectedRange,
                          onPickRange: _pickDateRange,
                          onClearRange: _clearDateRange,
                          onClearSearch: _clearSearch,
                        ),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    sliver: filtered.isEmpty
                        ? const SliverToBoxAdapter(
                            child: EmptyStateCard(
                              icon: Icons.history,
                              title: 'Sin historial por mostrar',
                              message:
                                  'No hay registros con los filtros seleccionados.',
                            ),
                          )
                        : SliverList(
                            delegate: SliverChildBuilderDelegate((
                              context,
                              index,
                            ) {
                              final record = filtered[index];
                              final isClosed = _isClosed(record);
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: _ServiceRecordCard(
                                  record: record,
                                  onTap: isClosed
                                      ? () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (_) => ReporteScreen(
                                                format: record.format,
                                                serviceId: record.id,
                                              ),
                                            ),
                                          );
                                        }
                                      : () {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Solo los servicios cerrados tienen PDF disponible.',
                                              ),
                                            ),
                                          );
                                        },
                                ),
                              );
                            }, childCount: filtered.length),
                          ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 80)),
                ],
              ),
              if (_showScrollToTop)
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: FloatingActionButton.small(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    shape: const CircleBorder(),
                    onPressed: _scrollToTop,
                    child: const Icon(Icons.keyboard_arrow_up),
                  ),
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

class _StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  _StickyHeaderDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
  });

  final double minHeight;
  final double maxHeight;
  final Widget child;

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface,
      child: SizedBox.expand(
        child: Align(
          alignment: Alignment.topCenter,
          child: child,
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _StickyHeaderDelegate oldDelegate) {
    return minHeight != oldDelegate.minHeight ||
        maxHeight != oldDelegate.maxHeight ||
        child != oldDelegate.child;
  }
}

class _ServiceHistoryFilters extends StatelessWidget {
  const _ServiceHistoryFilters({
    required this.searchController,
    required this.selectedRange,
    required this.onPickRange,
    required this.onClearRange,
    required this.onClearSearch,
  });

  final TextEditingController searchController;
  final DateTimeRange? selectedRange;
  final VoidCallback onPickRange;
  final VoidCallback onClearRange;
  final VoidCallback onClearSearch;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final range = selectedRange;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: searchController,
                    textInputAction: TextInputAction.search,
                    maxLines: 1,
                    textAlignVertical: TextAlignVertical.center,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      prefixIconConstraints: const BoxConstraints(
                        minWidth: 44,
                        minHeight: 36,
                      ),
                      suffixIcon: searchController.text.trim().isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Limpiar búsqueda',
                              onPressed: onClearSearch,
                              icon: const Icon(Icons.close),
                            ),
                      hintText: 'Buscar',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Tooltip(
                  message: range == null
                      ? 'Filtrar por rango de fechas'
                      : 'Quitar rango activo',
                  child: IconButton(
                    onPressed: range == null ? onPickRange : onClearRange,
                    icon: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Icon(
                          range == null
                              ? Icons.date_range_outlined
                              : Icons.date_range,
                        ),
                        if (range != null)
                          Positioned(
                            right: -1,
                            top: -1,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: scheme.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (range != null) ...[
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Rango: ${_short(range.start)} – ${_short(range.end)}',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _short(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)}/${d.year}';
  }
}

class _ServiceRecordCard extends StatelessWidget {
  const _ServiceRecordCard({required this.record, this.onTap});

  final ServiceRecord record;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = _formatAccentColor(scheme, record.format);
    final statusColor = _statusColor(scheme, record.status);
    final displayKey =
        (record.fileId != null && record.fileId!.trim().isNotEmpty)
            ? record.fileId!.trim()
            : record.id.toString();
    final dateText = _formatDate(record.dateCreated);
    final employeeText = (record.employeeName == null)
        ? '—'
        : record.employeeName!.trim();
    final statusText = (record.status == null) ? '—' : record.status!.trim();
    final hasObservations =
        record.observations != null && record.observations!.trim().isNotEmpty;

    final formatText = _formatServiceCode(record.format);
    final idOrFileText =
        (record.fileId != null && record.fileId!.trim().isNotEmpty)
            ? 'FILE $displayKey'
            : 'ID $displayKey';

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    formatText,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: accent,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          idOrFileText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: scheme.onSurfaceVariant,
                              ),
                        ),
                      ),
                      if (hasObservations) ...[
                        const SizedBox(width: 2),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          tooltip: 'Observaciones',
                          onPressed: () {
                            showDialog<void>(
                              context: context,
                              builder: (ctx) {
                                return AlertDialog(
                                  title: const Text('Observaciones'),
                                  content: Text(record.observations!.trim()),
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
                          icon: Icon(Icons.info_outline, color: scheme.primary),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                _FittedStatusChip(text: statusText, color: statusColor),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _LabeledText(
                    label: 'Técnico',
                    value: employeeText,
                    alignEnd: false,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _LabeledText(
                    label: 'Fecha',
                    value: dateText,
                    alignEnd: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      ),
    );
  }

  static String _formatDate(DateTime? value) {
    if (value == null) return '—';
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(value.day)}/${two(value.month)}/${value.year}';
  }

  static String _formatServiceCode(String raw) {
    final clean = raw.trim().replaceAll('-', '').toUpperCase();
    if (clean.isEmpty) return 'SIN FORMATO';
    final parts = <String>[];
    for (var i = 0; i < clean.length; i += 2) {
      final end = (i + 2) > clean.length ? clean.length : (i + 2);
      parts.add(clean.substring(i, end));
    }
    return parts.join('-');
  }

  static Color _statusColor(ColorScheme scheme, String? status) {
    final s = (status ?? '').trim().toLowerCase();
    if (s.contains('abierto') || s.contains('open')) {
      return scheme.primary;
    }
    if (s.contains('cerrado') || s.contains('closed')) {
      return scheme.secondary;
    }
    return scheme.primary;
  }

  static Color _formatAccentColor(ColorScheme scheme, String format) {
    switch (format.trim().toLowerCase()) {
      case 'fole01':
        return scheme.primary;
      case 'foim01':
        return scheme.secondary;
      case 'fosp01':
        return scheme.tertiary;
      case 'fosc01':
        return scheme.primary;
      case 'foos01':
        return scheme.secondary;
      case 'foem01':
        return scheme.tertiary;
      case 'fobc01':
        return scheme.error;
      case 'fopc02':
        return scheme.primary;
      default:
        return scheme.primary;
    }
  }
}

class _FittedStatusChip extends StatelessWidget {
  const _FittedStatusChip({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final label = text.trim().isEmpty ? '—' : text;
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: color,
                fontWeight: FontWeight.w900,
              ),
        ),
      ),
    );
  }
}

class _LabeledText extends StatelessWidget {
  const _LabeledText({
    required this.label,
    required this.value,
    this.alignEnd = false,
    this.valueEmphasis = false,
  });

  final String label;
  final String value;
  final bool alignEnd;
  final bool valueEmphasis;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final display = value.trim().isEmpty ? '—' : value;
    final align = alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start;

    return Column(
      crossAxisAlignment: align,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 2),
        Text(
          display,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: alignEnd ? TextAlign.right : TextAlign.left,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: valueEmphasis ? FontWeight.w900 : FontWeight.w700,
              ),
        ),
      ],
    );
  }
}
