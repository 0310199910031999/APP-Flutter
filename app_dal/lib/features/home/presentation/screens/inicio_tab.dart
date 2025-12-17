import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_dal/features/auth/providers/auth_provider.dart';

class InicioTab extends StatelessWidget {
  const InicioTab({super.key});

  @override
  Widget build(BuildContext context) {
    const stats = [
      _Stat(icon: Icons.construction, title: 'Equipos', value: '24', color: Colors.blue),
      _Stat(icon: Icons.assignment_turned_in, title: 'Rentas Activas', value: '8', color: Colors.green),
      _Stat(icon: Icons.pending_actions, title: 'Pendientes', value: '3', color: Colors.orange),
      _Stat(icon: Icons.attach_money, title: 'Ingresos', value: '\$12.5k', color: Colors.purple),
    ];

    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Inicio'),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _FadeSlideIn(
                  delay: const Duration(milliseconds: 60),
                  beginOffset: const Offset(0, 0.12),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 30,
                                backgroundColor: Theme.of(context).colorScheme.primary,
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
                                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      authProvider.state.user?.email ?? 'Usuario',
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            color: Colors.grey[600],
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                _FadeSlideIn(
                  delay: const Duration(milliseconds: 120),
                  beginOffset: const Offset(0, 0.1),
                  child: Text(
                    'Resumen',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                const SizedBox(height: 16),

                _FadeSlideIn(
                  delay: const Duration(milliseconds: 160),
                  beginOffset: const Offset(0, 0.14),
                  child: LayoutBuilder(
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
                          return _buildStatCard(
                            context,
                            icon: stat.icon,
                            title: stat.title,
                            value: stat.value,
                            color: stat.color,
                          );
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),

                _FadeSlideIn(
                  delay: const Duration(milliseconds: 220),
                  beginOffset: const Offset(0, 0.1),
                  child: Text(
                    'Actividad Reciente',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                const SizedBox(height: 16),
                _FadeSlideIn(
                  delay: const Duration(milliseconds: 260),
                  beginOffset: const Offset(0, 0.12),
                  child: _buildActivityItem(
                    context,
                    icon: Icons.add_circle_outline,
                    title: 'Nueva renta registrada',
                    subtitle: 'Hace 2 horas',
                  ),
                ),
                _FadeSlideIn(
                  delay: const Duration(milliseconds: 300),
                  beginOffset: const Offset(0, 0.12),
                  child: _buildActivityItem(
                    context,
                    icon: Icons.check_circle_outline,
                    title: 'Equipo devuelto',
                    subtitle: 'Hace 5 horas',
                  ),
                ),
                _FadeSlideIn(
                  delay: const Duration(milliseconds: 340),
                  beginOffset: const Offset(0, 0.12),
                  child: _buildActivityItem(
                    context,
                    icon: Icons.warning_amber_outlined,
                    title: 'Mantenimiento programado',
                    subtitle: 'Hace 1 día',
                  ),
                ),
              ],
            ),
          ),
        );
      },
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

  Widget _buildActivityItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
          child: Icon(icon, color: Theme.of(context).colorScheme.primary),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
      ),
    );
  }
}

class _FadeSlideIn extends StatefulWidget {
  const _FadeSlideIn({
    required this.child,
    this.delay = Duration.zero,
    this.beginOffset = const Offset(0, 0.1),
  });

  final Widget child;
  final Duration delay;
  final Offset beginOffset;

  @override
  State<_FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<_FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 420),
      vsync: this,
    );
    final curve = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _opacity = Tween<double>(begin: 0, end: 1).animate(curve);
    _offset = Tween<Offset>(begin: widget.beginOffset, end: Offset.zero).animate(curve);

    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _offset,
        child: widget.child,
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
