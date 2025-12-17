class AppConstants {
  // Storage keys
  static const String isLoggedInKey = 'is_logged_in';
  static const String userTokenKey = 'user_token';
  static const String userEmailKey = 'user_email';
  
  // API endpoints (para cuando implementes tu backend)
  static const String baseUrl = 'https://tu-api.com/api'; // Cambiar por tu URL
  static const String loginEndpoint = '/auth/login';
  static const String logoutEndpoint = '/auth/logout';
  
  // App info
  static const String appName = 'DAL App';
  
  // Validation
  static const int minPasswordLength = 6;
}
