import 'package:go_router/go_router.dart';
import 'package:app_dal/features/auth/presentation/screens/login_screen.dart';
import 'package:app_dal/features/home/presentation/screens/main_screen.dart';
import 'package:app_dal/features/auth/providers/auth_provider.dart';

class AppRouter {
  static GoRouter router(AuthProvider authProvider) {
    return GoRouter(
      initialLocation: '/login',
      refreshListenable: authProvider, // Recalcula redirects cuando cambia el auth
      redirect: (context, state) {
        // Si está cargando, no redirigir
        if (authProvider.state.isLoading) {
          return null;
        }
        
        final isAuthenticated = authProvider.state.isAuthenticated;
        final isGoingToLogin = state.matchedLocation == '/login';

        // Si no está autenticado y no va al login, redirigir al login
        if (!isAuthenticated && !isGoingToLogin) {
          return '/login';
        }

        // Si está autenticado y va al login, redirigir al home
        if (isAuthenticated && isGoingToLogin) {
          return '/';
        }

        // No hay redirección necesaria
        return null;
      },
      routes: [
        GoRoute(
          path: '/login',
          name: 'login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/',
          name: 'home',
          builder: (context, state) => const MainScreen(),
        ),
      ],
    );
  }
}
