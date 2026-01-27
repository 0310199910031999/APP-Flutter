import 'package:app_dal/features/equipos/models/equipo.dart';
import 'package:app_dal/features/equipos/models/inspection_record.dart';
import 'package:app_dal/features/equipos/presentation/detail/widgets/empty_state_card.dart';
import 'package:app_dal/features/equipos/presentation/detail/widgets/error_view.dart';
import 'package:app_dal/features/equipos/presentation/detail/screens/new_inspection_screen.dart';
import 'package:app_dal/features/equipos/presentation/report/reporte_screen.dart';
import 'package:app_dal/features/equipos/repositories/equipos_repository.dart';
import 'package:app_dal/features/equipos/repositories/inspection_records_repository.dart';
import 'package:flutter/material.dart';

class InspectionTab extends StatefulWidget {
  const InspectionTab({
    super.key,
    required this.equipo,
    required this.onRefreshEquipo,
  });

  final Equipo equipo;
  final Future<void> Function() onRefreshEquipo;

  @override
  State<InspectionTab> createState() => _InspectionTabState();
}

class _InspectionTabState extends State<InspectionTab>
    with AutomaticKeepAliveClientMixin {
  final EquiposRepository _equiposRepository = EquiposRepository();
  final _repository = InspectionRecordsRepository();
  late Future<List<InspectionRecord>> _future;
  final ScrollController _scrollController = ScrollController();
  bool _showScrollToTop = false;
  bool _hourometerModalOpen = false;

  @override
  void initState() {
    super.initState();
    _future = _repository.fetchByEquipmentId(widget.equipo.id);
    _scrollController.addListener(_onScrollChanged);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScrollChanged);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant InspectionTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.equipo.id != widget.equipo.id) {
      _future = _repository.fetchByEquipmentId(widget.equipo.id);
    }
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

  Future<void> _refreshInspections() async {
    await widget.onRefreshEquipo();
    setState(() {
      _future = _repository.fetchByEquipmentId(widget.equipo.id);
    });
    await _future;
  }

  Future<void> _startNewInspection() async {
    if (_hourometerModalOpen) return;
    final updated = await _showHourometerModal();
    if (updated != true) return;
    await _refreshInspections();
    if (!mounted) return;

    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => NewInspectionScreen(
          equipo: widget.equipo,
        ),
      ),
    );

    if (created == true && mounted) {
      await _refreshInspections();
    }
  }

  Future<bool?> _showHourometerModal() async {
    _hourometerModalOpen = true;
    final controller = TextEditingController(
      text: widget.equipo.hourometer.toString(),
    );
    String? errorText;
    bool saving = false;

    try {
      final result = await showModalBottomSheet<bool>(
        context: context,
        useRootNavigator: true,
        isScrollControlled: true,
        builder: (ctx) {
          final bottom = MediaQuery.of(ctx).viewInsets.bottom;
          return Padding(
            padding: EdgeInsets.only(bottom: bottom),
            child: StatefulBuilder(
              builder: (ctx, setModalState) {
                void safeSetModalState(VoidCallback fn) {
                  if (!ctx.mounted) return;
                  setModalState(fn);
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Actualizar horómetro',
                            style: Theme.of(ctx)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                          const Spacer(),
                          Text(
                            widget.equipo.economicNumber.isEmpty
                                ? 'Equipo sin número'
                                : 'Equipo ${widget.equipo.economicNumber}',
                            style: Theme.of(ctx)
                                .textTheme
                                .labelLarge
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: controller,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: 'Horómetro',
                          prefixIcon: const Icon(Icons.speed),
                          border: const OutlineInputBorder(),
                          errorText: errorText,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          TextButton(
                            onPressed: saving
                                ? null
                                : () {
                                    Navigator.of(ctx).pop(false);
                                  },
                            child: const Text('Cancelar'),
                          ),
                          const Spacer(),
                          FilledButton.icon(
                            onPressed: saving
                                ? null
                                : () async {
                                    safeSetModalState(() {
                                      errorText = null;
                                    });
                                    final raw = controller.text
                                        .trim()
                                        .replaceAll(',', '.');
                                    final value = double.tryParse(raw);
                                    if (value == null || value.isNaN) {
                                        safeSetModalState(() {
                                        errorText =
                                            'Ingresa un valor numérico para el horómetro';
                                      });
                                      return;
                                    }
                                    if (value < 0) {
                                        safeSetModalState(() {
                                        errorText = 'El horómetro no puede ser negativo';
                                      });
                                      return;
                                    }

                                    safeSetModalState(() {
                                      saving = true;
                                    });

                                    try {
                                      final ok = await _equiposRepository
                                          .updateHourometer(
                                        equipmentId: widget.equipo.id,
                                        hourometer: value,
                                      );

                                      if (!ok) {
                                        if (ctx.mounted) {
                                          ScaffoldMessenger.of(ctx).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'No se pudo actualizar el horómetro',
                                              ),
                                            ),
                                          );
                                        }
                                        safeSetModalState(() {
                                          saving = false;
                                        });
                                        return;
                                      }

                                      if (ctx.mounted) {
                                        ScaffoldMessenger.of(ctx).showSnackBar(
                                          const SnackBar(
                                            content: Text('Horómetro actualizado'),
                                          ),
                                        );
                                      }
                                      if (ctx.mounted) {
                                        Navigator.of(ctx).pop(true);
                                      }
                                    } catch (e) {
                                      if (ctx.mounted) {
                                        ScaffoldMessenger.of(ctx).showSnackBar(
                                          SnackBar(content: Text(e.toString())),
                                        );
                                      }
                                      safeSetModalState(() {
                                        saving = false;
                                      });
                                    }
                                  },
                            icon: saving
                                ? SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Theme.of(ctx).colorScheme.onPrimary,
                                      ),
                                    ),
                                  )
                                : const Icon(Icons.save_outlined),
                            label: const Text('Guardar y continuar'),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      );

      return result;
    } finally {
      // Espera a que el sheet termine su animación de cierre antes de liberar el controller.
      await Future<void>.delayed(const Duration(milliseconds: 60));
      try {
        controller.dispose();
      } catch (_) {
        // Ignora si ya fue liberado por el framework durante el cierre.
      }
      _hourometerModalOpen = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return RefreshIndicator(
      onRefresh: _refreshInspections,
      child: FutureBuilder<List<InspectionRecord>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return ErrorView(
              title: 'No se pudieron cargar las inspecciones',
              message: snapshot.error.toString(),
              onRetry: _refreshInspections,
            );
          }

          final records = snapshot.data ?? const <InspectionRecord>[];

          return Stack(
            children: [
              CustomScrollView(
                key: PageStorageKey('inspection-${widget.equipo.id}'),
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    sliver: SliverToBoxAdapter(
                      child: _InspectionHeroCard(
                        equipoName: widget.equipo.economicNumber,
                        onTap: _startNewInspection,
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    sliver: records.isEmpty
                        ? const SliverToBoxAdapter(
                            child: EmptyStateCard(
                              icon: Icons.history,
                              title: 'Sin inspecciones por mostrar',
                              message:
                                  'No hay inspecciones registradas para este equipo.',
                            ),
                          )
                        : SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: _InspectionRecordCard(
                                    record: records[index],
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => ReporteScreen(
                                            format: 'foim03',
                                            serviceId: records[index].id,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                );
                              },
                              childCount: records.length,
                            ),
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

class _InspectionHeroCard extends StatelessWidget {
  const _InspectionHeroCard({required this.equipoName, required this.onTap});

  final String equipoName;
  final VoidCallback onTap;

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
              child: Icon(Icons.fact_check_outlined, color: scheme.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Inspección visual',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Equipo ${equipoName.isEmpty ? 'sin número económico' : equipoName}.'
                    ' Revisa el historial o crea una nueva inspección visual.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      FilledButton.icon(
                        onPressed: onTap,
                        icon: const Icon(Icons.add_circle_outline),
                        label: const Text('Nueva inspección'),
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

class _InspectionRecordCard extends StatelessWidget {
  const _InspectionRecordCard({required this.record, this.onTap});

  final InspectionRecord record;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const formatText = 'FO-IM-03';
    final statusColor = _statusColor(scheme, record.status);
    final dateText = _formatDate(record.dateCreated);
    final userText = (record.appUserName == null)
        ? '—'
        : record.appUserName!.trim();
    final statusText = (record.status == null) ? '—' : record.status!.trim();
    final hasObservations =
        record.observations != null && record.observations!.trim().isNotEmpty;

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
                    color: scheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    formatText,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: scheme.primary,
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
                          'ID ${record.id}',
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
                      label: 'Usuario',
                      value: userText,
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
  });

  final String label;
  final String value;
  final bool alignEnd;

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
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }
}
