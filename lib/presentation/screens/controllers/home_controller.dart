import 'dart:math' as math;
import 'package:passwordmanager/core/encryption_service.dart';
import 'package:passwordmanager/core/extension/import_extensios.dart';
import 'package:passwordmanager/core/services/biometric_service.dart';

// ── Events ─────────────────────────────────────────────────────────────────
// The controller cannot show dialogs or snackbars directly (no BuildContext),
// so it emits typed events that the widget layer listens to and acts on.

enum HomeEvent {
  saveSuccess,
  needsEnrollment,
  logoutRequested,
}

class HomeEventPayload {
  const HomeEventPayload(this.event, {this.errorMessage});
  final HomeEvent event;
  final String? errorMessage; // non-null for error events
}

// ── Controller ─────────────────────────────────────────────────────────────

class HomeController with ChangeNotifier {
  HomeController({required TickerProvider vsync}) {
    _initAnimations(vsync);
  }

  // ── Form controllers ───────────────────────────────────────────────────────
  final siteController = TextEditingController();
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  // ── UI state ───────────────────────────────────────────────────────────────
  bool isLoading = false;
  bool isPasswordVisible = false;

  // ── Event stream ───────────────────────────────────────────────────────────
  // A lightweight alternative to streams: widget reads this after notifyListeners.
  HomeEventPayload? _lastEvent;
  HomeEventPayload? get lastEvent => _lastEvent;

  void _emit(HomeEvent event, {String? errorMessage}) {
    _lastEvent = HomeEventPayload(event, errorMessage: errorMessage);
    notifyListeners();
  }

  void consumeEvent() {
    _lastEvent = null;
    // No notifyListeners — consuming an event shouldn't trigger a rebuild.
  }

  // ── Animations ─────────────────────────────────────────────────────────────
  late final AnimationController entranceController;
  late final AnimationController shieldController;
  late final Animation<double> fadeIn;
  late final Animation<Offset> slideUp;
  late final Animation<double> shieldRotate;

  void _initAnimations(TickerProvider vsync) {
    entranceController = AnimationController(
      vsync: vsync,
      duration: const Duration(milliseconds: 1000),
    )..forward();

    shieldController = AnimationController(
      vsync: vsync,
      duration: const Duration(seconds: 4),
    )..repeat();

    fadeIn = CurvedAnimation(
      parent: entranceController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
    );

    slideUp = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: entranceController,
      curve: const Interval(0.1, 1.0, curve: Curves.easeOutCubic),
    ));

    shieldRotate = Tween<double>(begin: 0, end: 2 * math.pi).animate(
      CurvedAnimation(parent: shieldController, curve: Curves.linear),
    );
  }

  // ── Password visibility ────────────────────────────────────────────────────
  void togglePasswordVisibility() {
    isPasswordVisible = !isPasswordVisible;
    notifyListeners();
  }

  // ── Save password ──────────────────────────────────────────────────────────
  Future<void> savePassword() async {
    if (!formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _emit(HomeEvent.saveSuccess, errorMessage: 'User not logged in');
      return;
    }

    // Step 1: biometric gate
    final authResult = await BiometricService.instance.authenticate(
      reason: 'Verify your identity to encrypt and save this password',
    );

    if (!authResult.success) {
      if (authResult.needsEnrollment) {
        _emit(HomeEvent.needsEnrollment);
      } else {
        _emit(HomeEvent.saveSuccess,
            errorMessage: authResult.errorMessage ?? 'Authentication failed');
      }
      return;
    }

    _setLoading(true);

    try {
      // Step 2: encrypt
      final encryptedPassword = await EncryptionService.encrypt(
        passwordController.text.trim(),
      );

      // Step 3: persist
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('passwords')
          .add({
        'siteName': siteController.text.trim(),
        'user_name': usernameController.text.trim(),
        'password': '', // never store plaintext
        'encrypted_password': encryptedPassword,
        'createdAt': FieldValue.serverTimestamp(),
      });

      _clearForm();
      _emit(HomeEvent.saveSuccess);
    } catch (e) {
      _emit(HomeEvent.saveSuccess, errorMessage: 'Error saving password: $e');
    } finally {
      _setLoading(false);
    }
  }

  // ── Logout ─────────────────────────────────────────────────────────────────
  void requestLogout() => _emit(HomeEvent.logoutRequested);

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
  }

  // ── Validation ─────────────────────────────────────────────────────────────
  String? validateRequired(String? value, String field) {
    if (value == null || value.isEmpty) return 'Please enter $field';
    return null;
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  void _setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }

  void _clearForm() {
    siteController.clear();
    usernameController.clear();
    passwordController.clear();
  }

  // ── Dispose ────────────────────────────────────────────────────────────────
  @override
  void dispose() {
    siteController.dispose();
    usernameController.dispose();
    passwordController.dispose();
    entranceController.dispose();
    shieldController.dispose();
    super.dispose();
  }
}
