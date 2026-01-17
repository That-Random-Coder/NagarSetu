import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure storage helper for managing authentication tokens and user data.
/// Uses flutter_secure_storage for encrypted, persistent storage.
class SecureStorageService {
  SecureStorageService._();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  // Storage keys
  static const String _tokenKey = 'auth_token';
  static const String _userIdKey = 'user_id';
  static const String _userEmailKey = 'user_email';
  static const String _userNameKey = 'user_name';
  static const String _isLoggedInKey = 'is_logged_in';
  static const String _isWorkerKey = 'is_worker';

  /// Save authentication token
  static Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  /// Get stored authentication token
  static Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  /// Save user ID
  static Future<void> saveUserId(String id) async {
    await _storage.write(key: _userIdKey, value: id);
  }

  /// Get stored user ID
  static Future<String?> getUserId() async {
    return await _storage.read(key: _userIdKey);
  }

  /// Save user email
  static Future<void> saveUserEmail(String email) async {
    await _storage.write(key: _userEmailKey, value: email);
  }

  /// Get stored user email
  static Future<String?> getUserEmail() async {
    return await _storage.read(key: _userEmailKey);
  }

  /// Save user full name
  static Future<void> saveUserName(String name) async {
    await _storage.write(key: _userNameKey, value: name);
  }

  /// Get stored user full name
  static Future<String?> getUserName() async {
    return await _storage.read(key: _userNameKey);
  }

  /// Set login status
  static Future<void> setLoggedIn(bool value) async {
    await _storage.write(key: _isLoggedInKey, value: value.toString());
  }

  /// Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final value = await _storage.read(key: _isLoggedInKey);
    return value == 'true';
  }

  /// Set worker status
  static Future<void> setIsWorker(bool value) async {
    await _storage.write(key: _isWorkerKey, value: value.toString());
  }

  /// Check if user is a worker
  static Future<bool> isWorker() async {
    final value = await _storage.read(key: _isWorkerKey);
    return value == 'true';
  }

  /// Save all user data after successful login
  static Future<void> saveUserData({
    required String token,
    required String userId,
    String? email,
    String? fullName,
    bool isWorker = false,
  }) async {
    await Future.wait([
      saveToken(token),
      saveUserId(userId),
      if (email != null) saveUserEmail(email),
      if (fullName != null) saveUserName(fullName),
      setLoggedIn(true),
      setIsWorker(isWorker),
    ]);
  }

  /// Clear all stored data (for logout)
  static Future<void> clearAll() async {
    await _storage.deleteAll();
  }

  /// Clear only authentication data (keep other preferences)
  static Future<void> clearAuthData() async {
    await Future.wait([
      _storage.delete(key: _tokenKey),
      _storage.delete(key: _userIdKey),
      _storage.delete(key: _userEmailKey),
      _storage.delete(key: _userNameKey),
      _storage.delete(key: _isLoggedInKey),
      _storage.delete(key: _isWorkerKey),
    ]);
  }
}
