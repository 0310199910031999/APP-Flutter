import 'package:app_dal/features/auth/providers/auth_provider.dart';
import 'package:app_dal/features/home/models/dashboard_summary.dart';
import 'package:app_dal/features/home/repositories/dashboard_repository.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class InicioTab extends StatefulWidget {
  const InicioTab({super.key});

  @override
  State<InicioTab> createState() => _InicioTabState();
}

class _InicioTabState extends State<InicioTab>
    with AutomaticKeepAliveClientMixin {
  final _repository = DashboardRepository();

  bool _isLoading = false;
  String? _error;
  DashboardSummary? _summary;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadSummary());
  }

  @override
  bool get wantKeepAlive => true;

  Future<void> _loadSummary() async {
    final clientId = context.read<AuthProvider>().state.user?.clientId ?? 0;
    if (clientId <= 0) {
      setState(() {
        _summary = null;
        _error = 'Cliente no encontrado. Inicia sesión nuevamente.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await _repository.fetchSummary(clientId);
      if (!mounted) return;
      setState(() {
        _summary = data;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _summary = null;
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inicio'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadSummary,
        child: _buildContent(context),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_isLoading && _summary == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return _ErrorView(message: _error!, onRetry: _loadSummary);
    }

    final summary = _summary;
    if (summary == null) {
      return _ErrorView(
        message: 'No se pudo obtener la información.',
        onRetry: _loadSummary,
      );
    }

    final stats = [
      _Stat(
        icon: Icons.construction,
        title: 'Equipos',
        value: summary.equipmentCount.toString(),
        color: Colors.blue,
      ),
      _Stat(
        icon: Icons.assignment_turned_in,
        title: 'Rentas activas',
        value: summary.focr02Count.toString(),
        color: Colors.green,
      ),
      _Stat(
        icon: Icons.pending_actions,
        title: 'Pendientes',
        value: summary.openServices.toString(),
        color: Colors.orange,
      ),
      _Stat(
        icon: Icons.build_circle_outlined,
        title: 'Visitas',
        value: summary.closedServices.toString(),
        color: Colors.purple,
      ),
    ];

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _WelcomeCard(),
          const SizedBox(height: 24),
          Text(
            'Resumen',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final isSmall = constraints.maxWidth < 380;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: stats.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: isSmall ? 1.05 : 1.35,
                ),
                itemBuilder: (context, index) {
                  final stat = stats[index];
                  return RepaintBoundary(
                    child: _buildStatCard(
                      context,
                      icon: stat.icon,
                      title: stat.title,
                      value: stat.value,
                      color: stat.color,
                    ),
                  );
                },
              );
            },
          ),
          const SizedBox(height: 24),
          Text(
            'Actividad Reciente',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          if (summary.activity.isEmpty)
            _EmptyActivity()
          else
            Column(
              children: [
                for (var i = 0; i < summary.activity.length; i++)
                  RepaintBoundary(
                    child: _ActivityItem(activity: summary.activity[i]),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityItem extends StatelessWidget {
  const _ActivityItem({required this.activity});

  final DashboardActivity activity;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final formattedCode = _formatCode(activity.format);
    final dateText = _formatDate(activity.date);
    final idText = activity.id > 0 ? '#${activity.id} · ' : '';
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: scheme.primary.withValues(alpha: 0.12),
              child: Icon(Icons.article_outlined, color: scheme.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$idText$formattedCode',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.engineering_outlined, size: 16, color: scheme.onSurfaceVariant),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          activity.employeeName.isEmpty ? 'Técnico no asignado' : activity.employeeName,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: scheme.onSurfaceVariant),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.event_outlined, size: 16, color: scheme.onSurfaceVariant),
                      const SizedBox(width: 6),
                      Text(
                        dateText,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.flag_outlined, size: 16, color: scheme.onSurfaceVariant),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          activity.status.isEmpty ? 'Sin estado' : activity.status,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: scheme.onSurfaceVariant),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
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

  static String _formatCode(String raw) {
    final clean = raw.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toUpperCase();
    if (clean.isEmpty) return 'SIN CÓDIGO';
    final buffer = StringBuffer();
    for (var i = 0; i < clean.length; i++) {
      buffer.write(clean[i]);
      final next = i + 1;
      final shouldDash = next % 2 == 0 && next < clean.length;
      if (shouldDash) buffer.write('-');
    }
    return buffer.toString();
  }

  static String _formatDate(DateTime? value) {
    if (value == null) return 'Fecha no disponible';
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(value.day)}/${two(value.month)}/${value.year}';
  }
}

class _EmptyActivity extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Row(
          children: [
            Icon(Icons.inbox_outlined, color: scheme.onSurfaceVariant),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Sin actividad reciente',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WelcomeCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthProvider>().state.user;
    final scheme = Theme.of(context).colorScheme;
    final displayName = _formatName(user?.name, user?.lastname);
    final clientName = (user?.clientName ?? '').trim();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: scheme.primary,
              child: const Icon(
                Icons.person,
                size: 35,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '¡Bienvenido!',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    displayName.isEmpty ? 'Usuario' : displayName,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  if (clientName.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      'de $clientName',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: Colors.grey[600]),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatName(String? name, String? last) {
    final first = (name ?? '').trim();
    final lastName = (last ?? '').trim();
    final full = '$first $lastName'.trim();
    return full.isEmpty ? '' : full;
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

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

class _Stat {
  const _Stat({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String value;
  final Color color;
}
