import 'package:flutter/material.dart';

class FaqsScreen extends StatelessWidget {
  const FaqsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final faqs = <(String, String)>[
      (
        '¿Cómo cambio mi contraseña?',
        'Por seguridad, solicita el cambio al correo ti@ddg.com.mx.',
      ),
      (
        '¿Cómo activo notificaciones?',
        'Ve a Configuración > Notificaciones y acepta permisos.',
      ),
      (
        '¿Cómo reporto un problema?',
        'Escríbenos a soporte@ddg.com.mx con capturas.',
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('FAQs')),
      body: ListView.builder(
        itemCount: faqs.length,
        itemBuilder: (_, i) {
          final (question, answer) = faqs[i];
          return ExpansionTile(
            title: Text(question),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(answer),
              ),
            ],
          );
        },
      ),
    );
  }
}
