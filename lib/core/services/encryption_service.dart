import 'dart:convert';
import 'dart:math';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// AES-256-CBC encryption service.
///
/// The 256-bit key is generated once and stored in flutter_secure_storage
/// (backed by Android Keystore / iOS Keychain).
///
/// Biometric enforcement is handled at the APP level by local_auth in
/// home_page.dart and vault_page.dart — local_auth calls authenticate()
/// BEFORE encrypt() / decrypt() is ever called, so the key is only
/// accessed after the user passes biometrics.
///
/// Encrypted values are stored as "<base64url-IV>:<base64-ciphertext>"
/// which is safe to store in Firestore.
class EncryptionService {
  EncryptionService._();

  static const _keyAlias = 'passguard_aes_key_v1';

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  // ── Key management ────────────────────────────────────────────────────────

  /// Returns the AES-256 key, generating and storing it on first call.
  static Future<enc.Key> _getOrCreateKey() async {
    String? stored = await _storage.read(key: _keyAlias);

    if (stored == null) {
      final rng = Random.secure();
      final keyBytes = List<int>.generate(32, (_) => rng.nextInt(256));
      stored = base64Url.encode(keyBytes);
      await _storage.write(key: _keyAlias, value: stored);
    }

    return enc.Key(base64Url.decode(stored));
  }

  // ── Public API ────────────────────────────────────────────────────────────

  /// Encrypts [plainText].
  ///
  /// ⚠️ Always call local_auth.authenticate() BEFORE calling this.
  /// Returns "<base64url-IV>:<base64-ciphertext>" safe to store in Firestore.
  static Future<String> encrypt(String plainText) async {
    final key = await _getOrCreateKey();
    final iv = enc.IV.fromSecureRandom(16);
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));

    final encrypted = encrypter.encrypt(plainText, iv: iv);
    return '${base64Url.encode(iv.bytes)}:${encrypted.base64}';
  }

  /// Decrypts a value produced by [encrypt].
  ///
  /// ⚠️ Always call local_auth.authenticate() BEFORE calling this.
  /// Throws [FormatException] if [encryptedData] is malformed.
  static Future<String> decrypt(String encryptedData) async {
    final parts = encryptedData.split(':');
    if (parts.length != 2) {
      throw const FormatException(
        'Invalid encrypted format — expected "<iv>:<ciphertext>"',
      );
    }

    final key = await _getOrCreateKey();
    final iv = enc.IV(base64Url.decode(parts[0]));
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));

    return encrypter.decrypt64(parts[1], iv: iv);
  }

  /// Deletes the key from secure storage.
  ///
  /// ⚠️ All encrypted passwords become permanently unreadable.
  /// Only call on an explicit "reset vault" user action.
  static Future<void> deleteKey() async {
    await _storage.delete(key: _keyAlias);
  }

  /// Returns true if a key already exists in secure storage.
  static Future<bool> hasKey() async {
    final val = await _storage.read(key: _keyAlias);
    return val != null;
  }
}
