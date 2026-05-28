import 'package:shared_preferences/shared_preferences.dart';

class SessionService {
  static const _keyLastActive = 'last_active_epoch_ms';
  static const _keyLastEmail = 'last_email';
  static const _keyBiometricEnabled = 'biometric_enabled';
  static const _keyPermissionsRequested = 'permissions_requested';

  /// Update the last active timestamp to now.
  static Future<void> updateLastActive() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      _keyLastActive,
      DateTime.now().toUtc().millisecondsSinceEpoch,
    );
  }

  /// Return the saved last active DateTime in UTC, or null if not set.
  static Future<DateTime?> getLastActive() async {
    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getInt(_keyLastActive);
    if (v == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(v, isUtc: true);
  }

  /// Clear stored last active timestamp.
  static Future<void> clearLastActive() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyLastActive);
  }

  static Future<void> saveLastEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLastEmail, email.trim());
  }

  static Future<String?> getLastEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyLastEmail);
  }

  static Future<void> clearLastEmail() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyLastEmail);
  }

  static Future<void> setBiometricEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyBiometricEnabled, enabled);
  }

  static Future<bool> isBiometricEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyBiometricEnabled) ?? false;
  }

  static Future<void> setPermissionsRequested(bool requested) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyPermissionsRequested, requested);
  }

  static Future<bool> isPermissionsRequested() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyPermissionsRequested) ?? false;
  }

  /// Return true if the saved lastActive is older than [maxIdle]. If no value saved, returns false.
  static Future<bool> isExpired(Duration maxIdle) async {
    final last = await getLastActive();
    if (last == null) return false;
    final diff = DateTime.now().toUtc().difference(last);
    return diff > maxIdle;
  }
}
