import 'dart:math' as math;
import 'package:local_auth/local_auth.dart';
import 'package:passwordmanager/core/extension/import_extensios.dart';
import 'package:local_auth/error_codes.dart' as auth_error;
import 'package:app_settings/app_settings.dart';

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
