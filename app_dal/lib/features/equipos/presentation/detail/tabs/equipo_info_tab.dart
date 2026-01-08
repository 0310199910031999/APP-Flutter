import 'package:app_dal/features/equipos/models/equipo.dart';
import 'package:flutter/material.dart';

class EquipoInfoTab extends StatelessWidget {
  const EquipoInfoTab({
    super.key,
    required this.equipo,
    required this.onRefreshEquipo,
  });

  final Equipo equipo;
  final Future<void> Function() onRefreshEquipo;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefreshEquipo,
      child: ListView(
        key: PageStorageKey('equipo-info-${equipo.id}'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          _HeaderCard(equipo: equipo),
          const SizedBox(height: 16),
          _MetricRow(equipo: equipo),
          const SizedBox(height: 16),
          _AdditionalInfoCard(equipo: equipo),
        ],
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.equipo});

  final Equipo equipo;

  @override
  Widget build(BuildContext context) {
    final imageUrl = equipo.brandImageUrl;
    final scheme = Theme.of(context).colorScheme;

    Widget imageWidget() {
      if (imageUrl == null) {
        return Container(
          color: scheme.surfaceContainerHighest,
          alignment: Alignment.center,
          child: Icon(Icons.image_outlined, size: 44, color: scheme.outline),
        );
      }

      return Image.network(
        imageUrl,
        fit: BoxFit.contain,
        cacheWidth: 400, // Optimize for detail view
        errorBuilder: (_, __, ___) => Container(
          color: scheme.surfaceContainerHighest,
          alignment: Alignment.center,
          child: Icon(Icons.broken_image, size: 44, color: scheme.outline),
        ),
      );
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 3 / 2,
            child: SizedBox(width: double.infinity, child: imageWidget()),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Text(
              '${equipo.brand.name} · ${equipo.model}',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
            child: Text(
              equipo.type.name.trim().isEmpty ? '—' : equipo.type.name,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({required this.equipo});

  final Equipo equipo;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final items = [
      _MetricCard(
        label: '# Económico',
        value: equipo.economicNumber.trim().isEmpty
            ? '—'
            : equipo.economicNumber,
        icon: Icons.confirmation_number_outlined,
        color: scheme.primary,
      ),
      _MetricCard(
        label: 'Horómetro',
        value: '${equipo.hourometer}',
        icon: Icons.schedule,
        color: scheme.secondary,
      ),
      _MetricCard(
        label: 'HOD',
        value: '${equipo.doh}',
        icon: Icons.speed,
        color: scheme.tertiary,
      ),
      _MetricCard(
        label: 'Capacidad',
        value: equipo.capacity.isEmpty ? '—' : equipo.capacity,
        icon: Icons.local_shipping_outlined,
        color: scheme.primary,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.6,
      ),
      itemBuilder: (context, index) => items[index],
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
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 24, color: color),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value.trim().isEmpty ? '—' : value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                        ),
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

class _AdditionalInfoCard extends StatelessWidget {
  const _AdditionalInfoCard({required this.equipo});

  final Equipo equipo;

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
                Icon(
                  Icons.list_alt_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Info adicional',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _KeyValueRow(label: 'Número de serie', value: equipo.serialNumber),
            _KeyValueRow(label: 'Tipo de equipo', value: equipo.type.name),
            _KeyValueRow(label: 'Capacidad', value: equipo.capacity),
            _KeyValueRow(label: 'Motor', value: equipo.motor),
            _KeyValueRow(label: 'Aditamiento', value: equipo.addition),
            _KeyValueRow(label: '# económico', value: equipo.economicNumber),
            _KeyValueRow(label: 'Horómetro', value: '${equipo.hourometer}'),
            _KeyValueRow(label: 'DOH', value: '${equipo.doh}'),
          ],
        ),
      ),
    );
  }
}

class _KeyValueRow extends StatelessWidget {
  const _KeyValueRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final displayValue = value.trim().isEmpty ? '—' : value;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              displayValue,
              textAlign: TextAlign.right,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
