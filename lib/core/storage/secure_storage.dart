/// ─── Bamako Thrift — Secure Storage ───────────────────────────────────────
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Abstraction au-dessus de FlutterSecureStorage pour les données sensibles.
/// (tokens, clés, identifiants…)
class SecureStorage {
  final FlutterSecureStorage _storage;

  SecureStorage()
      : _storage = const FlutterSecureStorage(
          aOptions: AndroidOptions(encryptedSharedPreferences: true),
          iOptions: IOSOptions(
            accessibility: KeychainAccessibility.first_unlock,
          ),
        );

  Future<void> write({required String key, required String value}) =>
      _storage.write(key: key, value: value);

  Future<String?> read(String key) => _storage.read(key: key);

  Future<void> delete(String key) => _storage.delete(key: key);

  Future<void> deleteAll() => _storage.deleteAll();

  Future<Map<String, String>> readAll() => _storage.readAll();

  Future<bool> containsKey(String key) => _storage.containsKey(key: key);
}
