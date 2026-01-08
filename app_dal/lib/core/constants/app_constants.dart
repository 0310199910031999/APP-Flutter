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
  static const String equipmentByPropertyEndpoint = '/equipment/byProperty';
  static const String equipmentByClientEndpoint = '/equipment/byClient';
  static const String equipmentDetailEndpoint = '/equipment';
  static const String dashboardMobileEndpoint = '/dashboard/mobile';
  static const String serviceRecordsEndpoint = '/service-records';
  static const String responsivasByClientEndpoint = '/focr02/by-client';
  static const String appRequestsByEquipmentEndpoint = '/app-requests/equipment';
  static const String servicesEndpoint = '/services/get_all';
  static const String appRequestsCreateEndpoint = '/app-requests/create';
  static const String sparePartCategoriesEndpoint = '/spare-part-categories/get_all';
  static const String sparePartsEndpoint = '/spare-parts/get_all';
  static const String inspectionRecordsEndpoint = '/foim03get_table';
  static const String foimQuestionsEndpoint = '/foim01/questions';
  static const String foimCreateEndpoint = '/foim03create';
  static const String staticBrandPath = '/static/img/brands/';

  // App info
  static const String appName = 'DAL App';

  // Validation
  static const int minPasswordLength = 6;
}
