class AppConstants {
  // Storage keys
  static const String isLoggedInKey = 'is_logged_in';
  static const String userDataKey = 'user_data_json';
  static const String userTokenKey = 'user_token';
  static const String userEmailKey = 'user_email';

  // API endpoints
  static const String baseUrl = 'https://ddg.com.mx/dal';
  static const String loginEndpoint = '/appUsers/auth';
  static const String logoutEndpoint = '/auth/logout';
  static const String equipmentByClientEndpoint = '/equipment/byClient';
  static const String equipmentDetailEndpoint = '/equipment';
  static const String staticBrandPath = '/static/img/brands/';

  // App info
  static const String appName = 'DAL App';

  // Validation
  static const int minPasswordLength = 6;
}
