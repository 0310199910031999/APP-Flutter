import 'package:app_dal/core/notifications/notification_service.dart';
import 'package:app_dal/core/theme/theme_provider.dart';
import 'package:app_dal/features/auth/providers/auth_provider.dart';
import 'package:app_dal/features/configuracion/presentation/screens/aviso_privacidad_screen.dart';
import 'package:app_dal/features/configuracion/presentation/screens/faqs_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ConfiguracionTab extends StatelessWidget {
  const ConfiguracionTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer3<AuthProvider, ThemeProvider, NotificationService>(
      builder: (context, authProvider, themeProvider, notificationService, child) {
        return Scaffold(
          appBar: AppBar(
        title: const Text('Configuración'),
      ),
      body: ListView(
        children: [
          // Perfil
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      child: const Icon(Icons.person, size: 40, color: Colors.white),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            authProvider.state.user?.name ?? 'Usuario',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            authProvider.state.user?.email ?? '',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey[600],
                                ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () {
                        // TODO: Editar perfil
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Editar perfil')),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Secciones de configuración
          _buildSection(
            context,
            title: 'General',
            items: [
              SwitchListTile(
                secondary: const Icon(Icons.dark_mode_outlined),
                title: const Text('Tema oscuro'),
                subtitle: const Text('Alterna claro/oscuro y persiste la preferencia'),
                value: themeProvider.mode == ThemeMode.dark,
                onChanged: (isDark) {
                  themeProvider.setTheme(isDark ? ThemeMode.dark : ThemeMode.light);
                },
              ),
              _buildListTile(
                context,
                icon: Icons.notifications_outlined,
                title: 'Notificaciones',
                subtitle: 'Solicitar permisos locales',
                onTap: () async {
                  await notificationService.requestPermissions();
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Permisos de notificaciones solicitados')),
                  );
                },
              ),
              _buildListTile(
                context,
                icon: Icons.language_outlined,
                title: 'Idioma',
                subtitle: 'Español',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Seleccionar idioma')),
                  );
                },
              ),
            ],
          ),

          _buildSection(
            context,
            title: 'Cuenta',
            items: [
              _buildListTile(
                context,
                icon: Icons.security_outlined,
                title: 'Seguridad',
                subtitle: 'Cambiar contraseña',
                onTap: () {
                  showDialog<void>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Cambio de contraseña'),
                      content: const Text(
                        'Por seguridad, solicita el cambio al correo ti@ddg.com.mx',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Aceptar'),
                        ),
                      ],
                    ),
                  );
                },
              ),
              _buildListTile(
                context,
                icon: Icons.privacy_tip_outlined,
                title: 'Aviso de Privacidad',
                subtitle: 'Consulta el aviso de privacidad',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AvisoPrivacidadScreen()),
                  );
                },
              ),
            ],
          ),

          _buildSection(
            context,
            title: 'Soporte',
            items: [
              _buildListTile(
                context,
                icon: Icons.help_outline,
                title: 'Centro de ayuda',
                subtitle: 'Preguntas frecuentes y soporte',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const FaqsScreen()),
                  );
                },
              ),
              _buildListTile(
                context,
                icon: Icons.info_outline,
                title: 'Acerca de',
                subtitle: 'Versión 21.0.0',
                onTap: () {
                  showAboutDialog(
                    context: context,
                    applicationName: 'DAL App',
                    applicationVersion: '1.0.0',
                    applicationIcon: const Icon(Icons.construction, size: 48),
                  );
                },
              ),
            ],
          ),

          // Cerrar sesión
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: () => _showLogoutDialog(context),
              icon: const Icon(Icons.logout),
              label: const Text('Cerrar Sesión'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
        );
      },
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<Widget> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
        ),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(children: items),
        ),
      ],
    );
  }

  Widget _buildListTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<AuthProvider>().logout();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );
  }
}
