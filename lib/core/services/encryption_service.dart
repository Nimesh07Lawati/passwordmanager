import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// AES-256-CBC encryption service backed by a MASTER-PASSWORD-derived key.
///
/// ── Why this replaces the old device-random-key design ──────────────────
/// Previously the AES key was generated randomly on first launch and
/// stored only in flutter_secure_storage. An app reinstall (or switching
/// devices) permanently destroyed that key — and with it, every
/// previously-encrypted password, with no way to recover them.
///
/// Now the key is DERIVED from a master password the user sets, using
/// Argon2id (a memory-hard KDF resistant to brute force) with a random
/// per-user salt:
///
///     key = Argon2id(masterPassword, salt)
///
/// Only the salt and a non-reversible verifier hash are stored remotely
/// (in Firestore — wired up by the CALLER, see setupMasterPassword() /
/// unlockWithMasterPassword() docs below). The master password and the
/// derived key itself NEVER leave the device and are NEVER stored
/// anywhere in plaintext or in any recoverable form.
///
/// On reinstall or a new device: the user re-enters their master
/// password once, the salt is fetched from Firestore, the exact same
/// key is re-derived, and every existing encrypted password decrypts
/// normally again.
///
/// Biometrics (local_auth, unchanged — still enforced in vault_page.dart
/// / home_page.dart) continue to gate day-to-day access. The derived key
/// is cached in secure storage after a successful unlock so the user
/// isn't retyping their master password on every biometric prompt — only
/// after a reinstall, new device, or cleared app storage, when the local
/// cache is gone.
///
/// ── Wiring this up (caller responsibilities) ─────────────────────────────
/// This class does ONLY cryptography — it never touches Firestore. The
/// caller (e.g. a VaultKeyController) is responsible for:
///   1. Persisting `saltBase64` / `verifierBase64` to the user's Firestore
///      doc after setupMasterPassword().
///   2. Fetching those same two values from Firestore before calling
///      unlockWithMasterPassword() on a fresh install.
///   3. Calling hasCachedKey() at app start (after biometric auth) to
///      decide whether to go straight to the vault, or prompt for the
///      master password first.
class EncryptionService {
  EncryptionService._();

  static const _cachedKeyAlias = 'passguard_derived_key_v2';

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  static final _argon2 = Argon2id(
    memory: 19456, // ~19 MB — OWASP-recommended minimum for Argon2id
    iterations: 2,
    parallelism: 1,
    hashLength: 32, // 256-bit key
  );

  // ── First-time setup ─────────────────────────────────────────────────

  /// Call ONCE when the user sets their master password for the first
  /// time (e.g. during onboarding).
  ///
  /// Generates a random salt, derives the AES key from [masterPassword],
  /// caches the raw key bytes locally, and returns the (salt, verifier)
  /// pair the CALLER must persist to Firestore, e.g.:
  ///
  ///   final setup = await EncryptionService.setupMasterPassword(pw);
  ///   await FirebaseFirestore.instance.collection('users').doc(uid).set({
  ///     'kdfSalt': setup.saltBase64,
  ///     'keyVerifier': setup.verifierBase64,
  ///   }, SetOptions(merge: true));
  ///
  /// Never store masterPassword or the derived key itself — only these
  /// two derived, non-reversible values.
  static Future<MasterKeySetupResult> setupMasterPassword(
    String masterPassword,
  ) async {
    final salt = _randomBytes(16);
    final keyBytes = await _deriveKeyBytes(masterPassword, salt);
    final verifier = _verifierFor(keyBytes);

    await _cacheKeyLocally(keyBytes);

    return MasterKeySetupResult(
      saltBase64: base64Url.encode(salt),
      verifierBase64: base64Url.encode(verifier),
    );
  }

  // ── Unlock after reinstall / new device ──────────────────────────────

  /// Call when no cached key is found locally (reinstall, new device, or
  /// cleared app storage) but the user already has a vault — i.e.
  /// [saltBase64] / [verifierBase64] already exist in Firestore.
  ///
  /// Re-derives the key from [masterPassword] + the stored salt, checks
  /// it against the stored verifier, and — if correct — caches it
  /// locally so encrypt()/decrypt() work again.
  ///
  /// Returns true if the master password was correct and the vault is
  /// now unlocked; false if it was wrong. Always show a generic
  /// "incorrect master password" message on false — never reveal more.
  static Future<bool> unlockWithMasterPassword({
    required String masterPassword,
    required String saltBase64,
    required String verifierBase64,
  }) async {
    final salt = base64Url.decode(saltBase64);
    final keyBytes = await _deriveKeyBytes(masterPassword, salt);
    final verifier = _verifierFor(keyBytes);

    final matches = _constantTimeEquals(
      verifier,
      base64Url.decode(verifierBase64),
    );

    if (matches) {
      await _cacheKeyLocally(keyBytes);
    }
    return matches;
  }

  /// True if a key is currently cached locally — i.e. the user does NOT
  /// need to be prompted for their master password right now (only
  /// biometrics, as before). Check this at app start / vault open.
  static Future<bool> hasCachedKey() async {
    final val = await _storage.read(key: _cachedKeyAlias);
    return val != null;
  }

  /// Clears the locally cached key (e.g. on explicit logout). Does NOT
  /// affect the salt/verifier in Firestore or any encrypted data — the
  /// user can unlock again with unlockWithMasterPassword().
  static Future<void> clearCachedKey() async {
    await _storage.delete(key: _cachedKeyAlias);
  }

  /// Full local wipe. Deletes the cached key. The caller is also
  /// responsible for deleting kdfSalt/keyVerifier from Firestore and
  /// every encrypted_password entry, since none of it will ever be
  /// recoverable again. Only call on an explicit, confirmed
  /// "reset vault" user action.
  static Future<void> resetVault() async {
    await _storage.delete(key: _cachedKeyAlias);
  }

  // ── Encrypt / decrypt (same AES-256-CBC wire format as before) ───────

  /// Encrypts [plainText] using the cached derived key.
  ///
  /// ⚠️ Always call local_auth.authenticate() BEFORE calling this, and
  /// ensure hasCachedKey() is true first — if false, the caller must run
  /// unlockWithMasterPassword() before this will work.
  /// Returns "<base64url-IV>:<base64-ciphertext>", safe to store in
  /// Firestore.
  static Future<String> encrypt(String plainText) async {
    final key = await _requireCachedKey();
    final iv = enc.IV.fromSecureRandom(16);
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));

    final encrypted = encrypter.encrypt(plainText, iv: iv);
    return '${base64Url.encode(iv.bytes)}:${encrypted.base64}';
  }

  /// Decrypts a value produced by [encrypt].
  ///
  /// ⚠️ Always call local_auth.authenticate() BEFORE calling this.
  /// Throws [FormatException] if [encryptedData] is malformed, or
  /// [StateError] if no key is cached (caller must unlock with the
  /// master password first).
  static Future<String> decrypt(String encryptedData) async {
    final parts = encryptedData.split(':');
    if (parts.length != 2) {
      throw const FormatException(
        'Invalid encrypted format — expected "<iv>:<ciphertext>"',
      );
    }

    final key = await _requireCachedKey();
    final iv = enc.IV(base64Url.decode(parts[0]));
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));

    return encrypter.decrypt64(parts[1], iv: iv);
  }

  // ── Internal helpers ───────────────────────────────────────────────

  static Future<enc.Key> _requireCachedKey() async {
    final stored = await _storage.read(key: _cachedKeyAlias);
    if (stored == null) {
      throw StateError(
        'No encryption key cached locally. Call '
        'unlockWithMasterPassword() first — this is expected after a '
        'reinstall, new device, or cleared app storage.',
      );
    }
    return enc.Key(base64Url.decode(stored));
  }

  static Future<void> _cacheKeyLocally(Uint8List keyBytes) async {
    await _storage.write(
      key: _cachedKeyAlias,
      value: base64Url.encode(keyBytes),
    );
  }

  static Future<Uint8List> _deriveKeyBytes(
    String masterPassword,
    List<int> salt,
  ) async {
    final secretKey = await _argon2.deriveKeyFromPassword(
      password: masterPassword,
      nonce: salt,
    );
    final bytes = await secretKey.extractBytes();
    return Uint8List.fromList(bytes);
  }

  /// A one-way, non-reversible fingerprint of the derived key, safe to
  /// store remotely — lets us check "was the master password correct"
  /// without ever storing the key or the password itself.
  static Uint8List _verifierFor(Uint8List keyBytes) {
    return Uint8List.fromList(crypto.sha256.convert(keyBytes).bytes);
  }

  static Uint8List _randomBytes(int length) {
    final rng = Random.secure();
    return Uint8List.fromList(
      List<int>.generate(length, (_) => rng.nextInt(256)),
    );
  }

  /// Constant-time comparison to avoid timing side-channel leaks when
  /// checking the verifier.
  static bool _constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }
}

/// Result of [EncryptionService.setupMasterPassword] — the two values the
/// caller must persist to Firestore. Never persist the password or key.
class MasterKeySetupResult {
  const MasterKeySetupResult({
    required this.saltBase64,
    required this.verifierBase64,
  });

  final String saltBase64;
  final String verifierBase64;
}
