import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// تخزين آمن لرمز الوصول الخاص بالخادم (Laravel) باستخدام
/// Keystore على أندرويد و Keychain على iOS بدلاً من SharedPreferences النصية.
class SecureTokenStorage {
  SecureTokenStorage._();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const String _tokenKey = 'access_token';
  static const String _tokenSavedAtKey = 'access_token_saved_at';

  /// ذاكرة مؤقتة لتجنب قراءة التخزين الآمن مع كل طلب شبكة.
  static String? _cachedToken;
  static bool _loaded = false;

  static Future<void> saveToken(String token) async {
    _cachedToken = token;
    _loaded = true;
    await _storage.write(key: _tokenKey, value: token);
    await _storage.write(
      key: _tokenSavedAtKey,
      value: DateTime.now().toUtc().toIso8601String(),
    );
  }

  static Future<String?> getToken() async {
    if (_loaded) return _cachedToken;
    try {
      _cachedToken = await _storage.read(key: _tokenKey);
    } catch (_) {
      // قد يفشل فك التشفير بعد استعادة نسخة احتياطية للجهاز؛ نعامله كجلسة منتهية.
      await _safeDeleteAll();
      _cachedToken = null;
    }
    _loaded = true;
    return _cachedToken;
  }

  static Future<void> clear() async {
    _cachedToken = null;
    _loaded = true;
    await _safeDeleteAll();
  }

  /// نقل الرمز القديم المخزن كنص عادي في SharedPreferences (من الإصدارات السابقة)
  /// إلى التخزين الآمن ثم حذفه من مكانه القديم.
  static Future<void> migrateFromSharedPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final legacy = prefs.getString(_tokenKey);
    if (legacy != null && legacy.isNotEmpty) {
      final existing = await getToken();
      if (existing == null || existing.isEmpty) {
        await saveToken(legacy);
      }
      await prefs.remove(_tokenKey);
    }
  }

  static Future<void> _safeDeleteAll() async {
    try {
      await _storage.delete(key: _tokenKey);
      await _storage.delete(key: _tokenSavedAtKey);
    } catch (_) {}
  }
}
