import 'package:flutter/material.dart';

class RentaTab extends StatelessWidget {
  const RentaTab({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Rentas'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Activas'),
              Tab(text: 'Completadas'),
              Tab(text: 'Pendientes'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildRentasList(context, 'activas'),
            _buildRentasList(context, 'completadas'),
            _buildRentasList(context, 'pendientes'),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Crear nueva renta')),
            );
          },
          icon: const Icon(Icons.add),
          label: const Text('Nueva Renta'),
        ),
      ),
    );
  }

  Widget _buildRentasList(BuildContext context, String type) {
    final int itemCount;
    final Color statusColor;
    final IconData statusIcon;

    switch (type) {
      case 'activas':
        itemCount = 5;
        statusColor = Colors.green;
        statusIcon = Icons.play_circle_outline;
        break;
      case 'completadas':
        itemCount = 12;
        statusColor = Colors.blue;
        statusIcon = Icons.check_circle_outline;
        break;
      case 'pendientes':
        itemCount = 3;
        statusColor = Colors.orange;
        statusIcon = Icons.pending_outlined;
        break;
      default:
        itemCount = 0;
        statusColor = Colors.grey;
        statusIcon = Icons.circle_outlined;
    }

    if (itemCount == 0) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No hay rentas $type',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: statusColor.withValues(alpha: 0.2),
              child: Icon(statusIcon, color: statusColor),
            ),
            title: Text('Renta #${1000 + index}'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text('Cliente: Cliente ${index + 1}'),
                Text('Equipo: Excavadora CAT 320'),
                Text('Fecha: ${_getDate(index)}'),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.arrow_forward_ios, size: 16),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Detalles de Renta #${1000 + index}')),
                );
              },
            ),
            isThreeLine: true,
          ),
        );
      },
    );
  }

  String _getDate(int index) {
    final now = DateTime.now();
    final date = now.subtract(Duration(days: index * 2));
    return '${date.day}/${date.month}/${date.year}';
  }
}
