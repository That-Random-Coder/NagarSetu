import 'package:shared_preferences/shared_preferences.dart';

/// Service to track app launch state (first time vs returning user)
class AppStateService {
  AppStateService._();

  static const String _firstLaunchKey = 'isFirstLaunch';

  /// Check if this is the first time the app is launched
  static Future<bool> isFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_firstLaunchKey) ?? true;
  }

  /// Mark the app as having been launched before
  static Future<void> markAppLaunched() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_firstLaunchKey, false);
  }

  /// Reset to first launch state (useful for testing or logout)
  static Future<void> resetToFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_firstLaunchKey, true);
  }
}
