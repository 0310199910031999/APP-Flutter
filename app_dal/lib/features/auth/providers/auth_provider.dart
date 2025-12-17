import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_dal/features/auth/models/auth_state.dart';
import 'package:app_dal/features/auth/repositories/auth_repository.dart';

class AuthProvider extends ChangeNotifier {
  AuthState _state = AuthState(isAuthenticated: false, isLoading: true);
  late AuthRepository _repository;

  AuthState get state => _state;

  AuthProvider() {
    _initialize();
  }

  Future<void> _initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _repository = AuthRepository(prefs);
    await _checkAuthStatus();
  }

  // Verificar estado de autenticación al iniciar
  Future<void> _checkAuthStatus() async {
    try {
      final isLoggedIn = await _repository.isLoggedIn();
      
      if (isLoggedIn) {
        final email = _repository.getSavedEmail();
        _state = AuthState(
          isAuthenticated: true,
          user: User(
            id: '1',
            email: email ?? '',
            name: 'Usuario',
          ),
        );
      } else {
        _state = AuthState(isAuthenticated: false);
      }
      notifyListeners();
    } catch (e) {
      _state = AuthState(
        isAuthenticated: false,
        error: e.toString(),
      );
      notifyListeners();
    }
  }

  // Login
  Future<void> login(String email, String password) async {
    _state = AuthState(isAuthenticated: false, isLoading: true);
    notifyListeners();

    try {
      final userData = await _repository.login(email, password);
      
      _state = AuthState(
        isAuthenticated: true,
        user: User(
          id: userData['id'],
          email: userData['email'],
          name: userData['name'],
        ),
        isLoading: false,
      );
      notifyListeners();
    } catch (e) {
      _state = AuthState(
        isAuthenticated: false,
        isLoading: false,
        error: e.toString(),
      );
      notifyListeners();
    }
  }

  // Logout
  Future<void> logout() async {
    await _repository.logout();
    _state = AuthState(isAuthenticated: false);
    notifyListeners();
  }

  // Limpiar error
  void clearError() {
    _state = _state.copyWith(error: null);
    notifyListeners();
  }
}
