import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_dal/core/router/app_router.dart';
import 'package:app_dal/core/theme/app_theme.dart';
import 'package:app_dal/core/theme/theme_provider.dart';
import 'package:app_dal/core/theme/theme_repository_prefs.dart';
import 'package:app_dal/core/constants/app_constants.dart';
import 'package:app_dal/core/notifications/local_notification_service.dart';
import 'package:app_dal/core/notifications/notification_service.dart';
import 'package:app_dal/features/auth/providers/auth_provider.dart';
import 'package:go_router/go_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final themeProvider = ThemeProvider(ThemeRepositoryPrefs());
  await themeProvider.load();

  final notificationService = LocalNotificationService();
  await notificationService.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
        Provider<NotificationService>.value(value: notificationService),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const _AppWithRouter();
  }
}

class _AppWithRouter extends StatefulWidget {
  const _AppWithRouter();

  @override
  State<_AppWithRouter> createState() => _AppWithRouterState();
}

class _AppWithRouterState extends State<_AppWithRouter> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    final authProvider = context.read<AuthProvider>();
    _router = AppRouter.router(authProvider);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppConstants.appName,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: context.watch<ThemeProvider>().mode,
      debugShowCheckedModeBanner: false,
      routerConfig: _router,
    );
  }
}
