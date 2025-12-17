import 'package:flutter/material.dart';

class EquiposTab extends StatelessWidget {
  const EquiposTab({super.key});

  // Datos de prueba estructurados como llegarán del backend
  List<Equipo> get _mockEquipos => const [
        Equipo(
          id: '1',
          marca: 'Caterpillar',
          modelo: '320D',
          numeroSerie: 'CAT0320DPAW12345',
          numeroEconomico: 'ECO-045',
          imageUrl: 'https://images.unsplash.com/photo-1504215680853-026ed2a45def?auto=format&fit=crop&w=600&q=80',
        ),
        Equipo(
          id: '2',
          marca: 'John Deere',
          modelo: '850J',
          numeroSerie: 'JD0850JZXC98765',
          numeroEconomico: 'ECO-112',
          imageUrl: 'https://images.unsplash.com/photo-1512400625785-1c1c1f1c1c1c?auto=format&fit=crop&w=600&q=80',
        ),
        Equipo(
          id: '3',
          marca: 'Komatsu',
          modelo: 'PC210LC',
          numeroSerie: 'KMPC210LC00999',
          numeroEconomico: 'ECO-220',
          imageUrl: 'https://images.unsplash.com/photo-1503389152951-9f343605f61e?auto=format&fit=crop&w=600&q=80',
        ),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Equipos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16.0),
        itemCount: _mockEquipos.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final equipo = _mockEquipos[index];
          return _FadeSlideIn(
            delay: Duration(milliseconds: 60 * index),
            beginOffset: const Offset(-0.12, 0),
            child: _EquipoCard(equipo: equipo),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Agregar nuevo equipo')),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _EquipoCard extends StatelessWidget {
  const _EquipoCard({required this.equipo});

  final Equipo equipo;

  @override
  Widget build(BuildContext context) {
    return Card(
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
                height: 96,
                child: Image.network(
                  equipo.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.grey.shade200,
                    alignment: Alignment.center,
                    child: Icon(Icons.broken_image, color: Colors.grey.shade500),
                  ),
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
                    '${equipo.marca} · ${equipo.modelo}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  _InfoRow(label: 'N. Serie', value: equipo.numeroSerie),
                  _InfoRow(label: 'N. Económico', value: equipo.numeroEconomico),
                ],
              ),
            ),
          ],
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

class _FadeSlideIn extends StatefulWidget {
  const _FadeSlideIn({
    required this.child,
    this.delay = Duration.zero,
    this.beginOffset = const Offset(-0.1, 0),
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

class Equipo {
  const Equipo({
    required this.id,
    required this.marca,
    required this.modelo,
    required this.numeroSerie,
    required this.numeroEconomico,
    required this.imageUrl,
  });

  final String id;
  final String marca;
  final String modelo;
  final String numeroSerie;
  final String numeroEconomico;
  final String imageUrl;
}
