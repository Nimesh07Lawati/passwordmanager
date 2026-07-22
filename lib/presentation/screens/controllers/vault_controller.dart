import 'dart:math' as math;
import 'package:passwordmanager/core/extension/import_extensios.dart';
import 'package:local_auth/error_codes.dart' as auth_error;
import 'package:app_settings/app_settings.dart';
import 'package:passwordmanager/core/services/encryption_service.dart';

class VaultController with ChangeNotifier {
  VaultController({required TickerProvider vsync}) {
    _initAnimations(vsync);
    checkBiometricAvailability();
  }

  final LocalAuthentication _localAuth = LocalAuthentication();

  // ── State ──────────────────────────────────────────────────────────────────
  bool isAuthenticated = false;
  bool isAuthenticating = false;
  bool biometricAvailable = false;
  bool isEnrolled = true;
  String searchQuery = '';
  final searchController = TextEditingController();

  // ── Vault key state (master-password derived key) ────────────────────────
  /// True once EncryptionService has a usable key cached locally — i.e.
  /// encrypt()/decrypt() will work without prompting for the master
  /// password. False right after a reinstall, new device, or cleared
  /// app storage.
  bool vaultKeyReady = false;

  /// True if this account has EVER set up a master password (i.e.
  /// kdfSalt/keyVerifier already exist in Firestore). Used to decide
  /// whether to show "create a master password" (first time) or
  /// "enter your master password" (recovery) when vaultKeyReady is
  /// false.
  bool hasMasterPasswordSetup = false;

  /// True while checkVaultKeyStatus() is fetching Firestore state.
  bool isCheckingVaultKey = false;

  // ── Animations ─────────────────────────────────────────────────────────────
  late final AnimationController shieldController;
  late final AnimationController entranceController;
  late final AnimationController lockController;
  late final Animation<double> shieldRotate;
  late final Animation<double> fadeIn;
  late final Animation<Offset> slideUp;
  late final Animation<double> lockScale;
  late final Animation<double> lockShake;

  void _initAnimations(TickerProvider vsync) {
    shieldController = AnimationController(
      vsync: vsync,
      duration: const Duration(seconds: 4),
    )..repeat();

    entranceController = AnimationController(
      vsync: vsync,
      duration: const Duration(milliseconds: 900),
    )..forward();

    lockController = AnimationController(
      vsync: vsync,
      duration: const Duration(milliseconds: 600),
    );

    shieldRotate = Tween<double>(begin: 0, end: 2 * math.pi).animate(
      CurvedAnimation(parent: shieldController, curve: Curves.linear),
    );

    fadeIn = CurvedAnimation(
      parent: entranceController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
    );

    slideUp = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: entranceController,
      curve: const Interval(0.1, 1.0, curve: Curves.easeOutCubic),
    ));

    lockScale = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.15), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.15, end: 1.0), weight: 50),
    ]).animate(
        CurvedAnimation(parent: lockController, curve: Curves.easeInOut));

    lockShake = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -8.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: -8.0, end: 8.0), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 8.0, end: -4.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: -4.0, end: 0.0), weight: 20),
    ]).animate(
        CurvedAnimation(parent: lockController, curve: Curves.easeInOut));
  }

  // ── Biometrics ─────────────────────────────────────────────────────────────
  Future<void> checkBiometricAvailability() async {
    try {
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      final canCheckBiometrics = await _localAuth.canCheckBiometrics;
      final enrolledBiometrics = await _localAuth.getAvailableBiometrics();
      biometricAvailable = isDeviceSupported;
      isEnrolled = canCheckBiometrics && enrolledBiometrics.isNotEmpty;
    } catch (_) {
      biometricAvailable = false;
      isEnrolled = false;
    }
    notifyListeners();
  }

  Future<bool> authenticate() async {
    if (isAuthenticating) return false;
    isAuthenticating = true;
    notifyListeners();
    lockController.forward(from: 0);

    try {
      final result = await _localAuth.authenticate(
        localizedReason: 'Authenticate to view your saved passwords',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );
      if (result) {
        isAuthenticated = true;
        entranceController.forward(from: 0);
        // Biometrics only gate the app — they say nothing about whether
        // the AES key is available. Check that separately so the UI can
        // show a master-password prompt when needed (reinstall, new
        // device, cleared storage) instead of just failing to decrypt.
        await checkVaultKeyStatus();
      }
      return result;
    } on PlatformException catch (e) {
      if (e.code == auth_error.notEnrolled) {
        isEnrolled = false;
      }
      rethrow; // let the UI layer handle snackbars
    } finally {
      isAuthenticating = false;
      notifyListeners();
    }
  }

  void lockVault() {
    isAuthenticated = false;
    entranceController.forward(from: 0);
    notifyListeners();
  }

  void updateSearch(String query) {
    searchQuery = query.toLowerCase();
    notifyListeners();
  }

  // ── Vault key (master password) ─────────────────────────────────────────

  /// Call after biometric auth succeeds. Determines whether the derived
  /// AES key is already cached locally, and — if not — whether this
  /// account needs to CREATE a master password (first time ever) or
  /// RE-ENTER one (key was lost locally but a vault already exists).
  ///
  /// After this call, check [vaultKeyReady]:
  ///   - true  → proceed straight to the vault, decrypt() works.
  ///   - false → show the master-password setup screen if
  ///             [hasMasterPasswordSetup] is false, or the
  ///             master-password unlock screen if it's true.
  Future<void> checkVaultKeyStatus() async {
    isCheckingVaultKey = true;
    notifyListeners();

    try {
      vaultKeyReady = await EncryptionService.hasCachedKey();
      if (!vaultKeyReady) {
        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid == null) {
          hasMasterPasswordSetup = false;
          return;
        }
        final doc =
            await FirebaseFirestore.instance.collection('users').doc(uid).get();
        final data = doc.data();
        hasMasterPasswordSetup = data != null &&
            data['kdfSalt'] != null &&
            data['keyVerifier'] != null;
      }
    } finally {
      isCheckingVaultKey = false;
      notifyListeners();
    }
  }

  /// First-time master password creation. Persists the salt + verifier
  /// (never the password or key) to the user's Firestore doc.
  ///
  /// Returns true on success. Throws if the user isn't signed in.
  Future<bool> createMasterPassword(String masterPassword) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      throw StateError('No signed-in user — cannot create master password.');
    }

    final setup = await EncryptionService.setupMasterPassword(masterPassword);

    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'kdfSalt': setup.saltBase64,
      'keyVerifier': setup.verifierBase64,
    }, SetOptions(merge: true));

    vaultKeyReady = true;
    hasMasterPasswordSetup = true;
    notifyListeners();
    return true;
  }

  /// Recovery flow — re-enter the master password after a reinstall,
  /// new device, or cleared app storage. Fetches the existing salt +
  /// verifier from Firestore and re-derives the key.
  ///
  /// Returns true if [masterPassword] was correct and the vault is now
  /// unlocked; false if it was wrong. Show a generic "incorrect master
  /// password" message on false — don't reveal anything more specific.
  Future<bool> unlockWithMasterPassword(String masterPassword) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return false;

    final doc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final data = doc.data();
    final salt = data?['kdfSalt'] as String?;
    final verifier = data?['keyVerifier'] as String?;
    if (salt == null || verifier == null) return false;

    final unlocked = await EncryptionService.unlockWithMasterPassword(
      masterPassword: masterPassword,
      saltBase64: salt,
      verifierBase64: verifier,
    );

    if (unlocked) {
      vaultKeyReady = true;
      notifyListeners();
    }
    return unlocked;
  }

  /// Full vault reset — used only when the user has forgotten their
  /// master password and there is no other way to recover it. Deletes
  /// every saved password (none of them will ever be decryptable again
  /// without the original master password), clears the local key cache,
  /// and removes kdfSalt/keyVerifier from Firestore so the user can set
  /// up a brand new master password from scratch.
  ///
  /// The caller MUST get explicit, unambiguous confirmation from the
  /// user before calling this — it is irreversible.
  Future<void> resetVaultAndForgetMasterPassword() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final passwords = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('passwords')
        .get();
    for (final doc in passwords.docs) {
      await doc.reference.delete();
    }

    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'kdfSalt': FieldValue.delete(),
      'keyVerifier': FieldValue.delete(),
    }, SetOptions(merge: true));

    await EncryptionService.resetVault();

    vaultKeyReady = false;
    hasMasterPasswordSetup = false;
    notifyListeners();
  }

  // ── Delete ─────────────────────────────────────────────────────────────────
  Future<void> deletePassword({
    required String docId,
    required String uid,
  }) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('passwords')
        .doc(docId)
        .delete();
  }

  // ── Settings ───────────────────────────────────────────────────────────────
  Future<void> openSecuritySettings() async {
    await AppSettings.openAppSettings(type: AppSettingsType.security);
  }

  @override
  void dispose() {
    shieldController.dispose();
    entranceController.dispose();
    lockController.dispose();
    searchController.dispose();
    super.dispose();
  }
}
