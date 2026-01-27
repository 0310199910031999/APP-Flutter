import 'package:flutter/material.dart';
import 'theme_repository.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeProvider(this._repository);

  final ThemeRepository _repository;
  ThemeMode _mode = ThemeMode.system;
  ThemeMode get mode => _mode;

  Future<void> load() async {
    _mode = await _repository.loadThemeMode();
    notifyListeners();
  }

  Future<void> setTheme(ThemeMode mode) async {
    _mode = mode;
    notifyListeners();
    await _repository.saveThemeMode(mode);
  }
}
