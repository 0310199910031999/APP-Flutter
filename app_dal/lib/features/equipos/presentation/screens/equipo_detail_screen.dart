import 'package:app_dal/features/equipos/models/equipo.dart';
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
  late Future<Equipo> _future;

  @override
  void initState() {
    super.initState();
    _future = _repository.fetchById(widget.equipoId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de equipo'),
      ),
      body: FutureBuilder<Equipo>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _ErrorView(
              message: snapshot.error.toString(),
              onRetry: () {
                setState(() {
                  _future = _repository.fetchById(widget.equipoId);
                });
              },
            );
          }
          final equipo = snapshot.data!;
          return _DetailContent(
            equipo: equipo,
            onRefresh: () async {
              setState(() {
                _future = _repository.fetchById(widget.equipoId);
              });
            },
          );
        },
      ),
    );
  }
}

class _DetailContent extends StatelessWidget {
  const _DetailContent({required this.equipo, required this.onRefresh});

  final Equipo equipo;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 760;

          final leftColumn = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Header(equipo: equipo),
              const SizedBox(height: 16),
              _MetricRow(equipo: equipo),
              const SizedBox(height: 16),
              _InfoGrid(equipo: equipo),
            ],
          );

          final rightColumn = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _QuickActions(),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Servicios realizados',
                icon: Icons.handyman_outlined,
                body: const _PlaceholderList(text: 'Aquí verás el historial de servicios realizados.'),
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Inspecciones',
                icon: Icons.fact_check_outlined,
                body: const _PlaceholderList(text: 'Consulta y realiza inspecciones desde aquí.'),
                trailing: TextButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Realizar inspección (pendiente de implementar)')),
                    );
                  },
                  icon: const Icon(Icons.add_task_outlined),
                  label: const Text('Nueva inspección'),
                ),
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Refacciones',
                icon: Icons.build_outlined,
                body: const _PlaceholderList(text: 'Solicita y da seguimiento a refacciones.'),
                trailing: TextButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Solicitar refacción (pendiente de implementar)')),
                    );
                  },
                  icon: const Icon(Icons.shopping_cart_outlined),
                  label: const Text('Solicitar refacción'),
                ),
              ),
            ],
          );

          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: isWide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: leftColumn),
                      const SizedBox(width: 16),
                      Expanded(flex: 2, child: rightColumn),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      leftColumn,
                      const SizedBox(height: 16),
                      rightColumn,
                    ],
                  ),
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.equipo});

  final Equipo equipo;

  @override
  Widget build(BuildContext context) {
    final imageUrl = equipo.brandImageUrl;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 96,
                height: 96,
                child: imageUrl == null
                    ? Container(
                        color: Colors.grey.shade200,
                        alignment: Alignment.center,
                        child: Icon(Icons.image_outlined, color: Colors.grey.shade500),
                      )
                    : Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.grey.shade200,
                          alignment: Alignment.center,
                          child: Icon(Icons.broken_image, color: Colors.grey.shade500),
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${equipo.brand.name} · ${equipo.model}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    equipo.type.name,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    runSpacing: 6,
                    children: [
                      _Chip(text: 'Serie: ${equipo.serialNumber}'),
                      _Chip(text: 'Económico: ${equipo.economicNumber}'),
                      _Chip(text: 'Mástil: ${equipo.mast}'),
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

class _InfoGrid extends StatelessWidget {
  const _InfoGrid({required this.equipo});

  final Equipo equipo;

  @override
  Widget build(BuildContext context) {
    final items = <MapEntry<String, String>>[
      MapEntry('Hourometer', '${equipo.hourometer}'),
      MapEntry('DOH', '${equipo.doh}'),
      MapEntry('Capacidad', equipo.capacity),
      MapEntry('Adición', equipo.addition),
      MapEntry('Motor', equipo.motor),
      MapEntry('Propiedad', equipo.property),
      MapEntry('Cliente', '${equipo.clientId}'),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 520;
            final crossAxisCount = isWide ? 2 : 1;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: isWide ? 3.6 : 3.2,
              ),
              itemBuilder: (context, index) {
                final item = items[index];
                return _InfoTile(label: item.key, value: item.value);
              },
            );
          },
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 6),
          Text(
            value.isEmpty ? '—' : value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _PlaceholderList extends StatelessWidget {
  const _PlaceholderList({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
    );
  }
}

class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 520;
        final children = [
          _ActionButton(
            icon: Icons.handyman_outlined,
            label: 'Solicitar servicio',
            color: Theme.of(context).colorScheme.primary,
            onTap: () => _showPending(context, 'Solicitar servicio'),
          ),
          _ActionButton(
            icon: Icons.fact_check_outlined,
            label: 'Realizar inspección',
            color: Colors.orange.shade700,
            onTap: () => _showPending(context, 'Realizar inspección'),
          ),
          _ActionButton(
            icon: Icons.shopping_cart_outlined,
            label: 'Solicitar refacción',
            color: Colors.teal.shade700,
            onTap: () => _showPending(context, 'Solicitar refacción'),
          ),
        ];

        return isWide
            ? Row(
                children: [
                  for (final child in children) Expanded(child: child),
                ],
              )
            : Column(
                children: [
                  for (int i = 0; i < children.length; i++) ...[
                    children[i],
                    if (i != children.length - 1) const SizedBox(height: 10),
                  ],
                ],
              );
      },
    );
  }

  static void _showPending(BuildContext context, String action) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$action (pendiente de implementar)')),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: color,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({required this.equipo});

  final Equipo equipo;

  @override
  Widget build(BuildContext context) {
    final items = [
      _MetricCard(
        label: 'Horas',
        value: '${equipo.hourometer}',
        icon: Icons.schedule,
        color: Theme.of(context).colorScheme.primary,
      ),
      _MetricCard(
        label: 'DOH',
        value: '${equipo.doh}',
        icon: Icons.speed,
        color: Colors.orange.shade700,
      ),
      _MetricCard(
        label: 'Capacidad',
        value: equipo.capacity.isEmpty ? '—' : equipo.capacity,
        icon: Icons.local_shipping_outlined,
        color: Colors.teal.shade700,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 520;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: items
              .map((e) => SizedBox(
                    width: isWide ? (constraints.maxWidth - 24) / 3 : double.infinity,
                    child: e,
                  ))
              .toList(),
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
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
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
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

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.body,
    this.trailing,
  });

  final String title;
  final IconData icon;
  final Widget body;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: 12),
            body,
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('No se pudo cargar el equipo', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.red)),
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
