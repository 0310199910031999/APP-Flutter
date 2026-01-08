import 'package:app_dal/features/auth/providers/auth_provider.dart';
import 'package:app_dal/features/equipos/models/equipo.dart';
import 'package:app_dal/features/equipos/providers/equipos_provider.dart';
import 'package:app_dal/features/equipos/repositories/equipos_repository.dart';
import 'package:app_dal/features/equipos/presentation/detail/equipo_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class EquiposTab extends StatefulWidget {
  const EquiposTab({super.key});

  @override
  State<EquiposTab> createState() => _EquiposTabState();
}

class _EquiposTabState extends State<EquiposTab> {
  late final EquiposProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = EquiposProvider(EquiposRepository());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>().state;
      final clientId = auth.user?.clientId;
      if (clientId != null) {
        _provider.loadEquipos(clientId);
      } else {
        _provider
            .loadEquipos(0); // triggers error for missing client; keeps UI consistent
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _provider,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Equipos'),
        ),
        body: Consumer<EquiposProvider>(
          builder: (context, equiposProvider, _) {
            if (equiposProvider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (equiposProvider.error != null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'No se pudieron cargar los equipos',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        equiposProvider.error!,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.red),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: () {
                          final auth = context.read<AuthProvider>().state;
                          final clientId = auth.user?.clientId;
                          if (clientId != null) {
                            equiposProvider.loadEquipos(clientId);
                          }
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reintentar'),
                      ),
                    ],
                  ),
                ),
              );
            }

            final equipos = equiposProvider.equipos;
            if (equipos.isEmpty) {
              return const Center(child: Text('No hay equipos disponibles.'));
            }

            return RefreshIndicator(
              onRefresh: () async {
                final auth = context.read<AuthProvider>().state;
                final clientId = auth.user?.clientId;
                if (clientId != null) {
                  await equiposProvider.loadEquipos(clientId);
                }
              },
              child: ListView.separated(
                padding: const EdgeInsets.all(16.0),
                itemCount: equipos.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final equipo = equipos[index];
                  return RepaintBoundary(
                    child: _EquipoCard(
                      equipo: equipo,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => EquipoDetailScreen(equipoId: equipo.id),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

class _EquipoCard extends StatelessWidget {
  const _EquipoCard({required this.equipo, required this.onTap});

  final Equipo equipo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final imageUrl = equipo.brandImageUrl;
    final placeholder = Container(
      color: Colors.grey.shade200,
      alignment: Alignment.center,
      child: Icon(Icons.image_outlined, color: Colors.grey.shade500),
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
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
                            errorBuilder: (_, error, ___) {
                              debugPrint('Error cargando imagen $imageUrl -> $error');
                              return placeholder;
                            },
                            loadingBuilder: (context, child, progress) {
                              if (progress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  value: progress.expectedTotalBytes != null
                                      ? progress.cumulativeBytesLoaded / (progress.expectedTotalBytes ?? 1)
                                      : null,
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
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      _InfoRow(label: 'Tipo', value: equipo.type.name),
                      _InfoRow(label: 'N. Serie', value: equipo.serialNumber),
                      _InfoRow(label: 'N. Económico', value: equipo.economicNumber),
                    ],
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

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: RichText(
        text: TextSpan(
          style: Theme.of(context).textTheme.bodyMedium,
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}

// Model is now defined in features/equipos/models/equipo.dart
