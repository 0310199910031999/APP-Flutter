import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_dal/core/constants/app_constants.dart';

class AuthRepository {
  final SharedPreferences _prefs;

  AuthRepository(this._prefs);

  // Login simulado - Cambia esto cuando tengas tu API
  Future<Map<String, dynamic>> login(String email, String password) async {
    // Simulación de delay de red
    await Future.delayed(const Duration(seconds: 1));

    // Credenciales de prueba (eliminar cuando tengas API real)
    if (email == 'admin@test.com' && password == '123456') {
      final userData = {
        'id': '1',
        'email': email,
        'name': 'Usuario Admin',
        'token': 'fake_token_12345', // Token simulado
      };

      // Guardar sesión
      await _prefs.setBool(AppConstants.isLoggedInKey, true);
      await _prefs.setString(AppConstants.userEmailKey, email);
      await _prefs.setString(AppConstants.userTokenKey, userData['token']!);

      return userData;
    } else {
      throw Exception('Credenciales inválidas');
    }
  }

  // Verificar si hay sesión guardada
  Future<bool> isLoggedIn() async {
    return _prefs.getBool(AppConstants.isLoggedInKey) ?? false;
  }

  // Obtener email guardado
  String? getSavedEmail() {
    return _prefs.getString(AppConstants.userEmailKey);
  }

  // Obtener token guardado
  String? getSavedToken() {
    return _prefs.getString(AppConstants.userTokenKey);
  }

  // Logout
  Future<void> logout() async {
    await _prefs.remove(AppConstants.isLoggedInKey);
    await _prefs.remove(AppConstants.userEmailKey);
    await _prefs.remove(AppConstants.userTokenKey);
  }

  /* 
   * IMPLEMENTACIÓN FUTURA CON API REST:
   * 
   * import 'package:dio/dio.dart';
   * 
   * Future<Map<String, dynamic>> loginWithAPI(String email, String password) async {
   *   try {
   *     final dio = Dio();
   *     final response = await dio.post(
   *       '${AppConstants.baseUrl}${AppConstants.loginEndpoint}',
   *       data: {
   *         'email': email,
   *         'password': password,
   *       },
   *     );
   * 
   *     if (response.statusCode == 200) {
   *       final userData = response.data;
   *       
   *       // Guardar sesión
   *       await _prefs.setBool(AppConstants.isLoggedInKey, true);
   *       await _prefs.setString(AppConstants.userEmailKey, userData['email']);
   *       await _prefs.setString(AppConstants.userTokenKey, userData['token']);
   *       
   *       return userData;
   *     } else {
   *       throw Exception('Error en el login');
   *     }
   *   } catch (e) {
   *     throw Exception('Error de conexión: $e');
   *   }
   * }
   */
}
