import 'dart:math' as math;
import 'package:passwordmanager/core/extension/import_extensios.dart';

// ── Events ─────────────────────────────────────────────────────────────────

enum LoginEvent {
  loginSuccess,
  loginError,
}

class LoginEventPayload {
  const LoginEventPayload(this.event, {this.errorMessage});
  final LoginEvent event;
  final String? errorMessage;
}

// ── Controller ─────────────────────────────────────────────────────────────

class LoginController with ChangeNotifier {
  LoginController({required TickerProvider vsync}) {
    _initAnimations(vsync);
  }

  // ── Form ───────────────────────────────────────────────────────────────────
  final formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  // ── UI state ───────────────────────────────────────────────────────────────
  bool isLoading = false;
  bool isPasswordVisible = false;

  // ── Event ──────────────────────────────────────────────────────────────────
  LoginEventPayload? _lastEvent;
  LoginEventPayload? get lastEvent => _lastEvent;

  void _emit(LoginEvent event, {String? errorMessage}) {
    _lastEvent = LoginEventPayload(event, errorMessage: errorMessage);
    notifyListeners();
  }

  void consumeEvent() => _lastEvent = null;

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

  // ── Login ──────────────────────────────────────────────────────────────────
  Future<void> login() async {
    if (!formKey.currentState!.validate()) return;

    _setLoading(true);

    try {
      final userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      final user = userCredential.user;
      if (user != null) {
        final userDoc =
            FirebaseFirestore.instance.collection('users').doc(user.uid);
        final docSnapshot = await userDoc.get();
        if (!docSnapshot.exists) {
          await userDoc.set({
            'email': user.email,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      }

      _emit(LoginEvent.loginSuccess);
    } on FirebaseAuthException catch (e) {
      _emit(LoginEvent.loginError, errorMessage: _mapAuthError(e));
    } finally {
      _setLoading(false);
    }
  }

  // ── Validation ─────────────────────────────────────────────────────────────
  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'Please enter your email';
    if (!value.contains('@')) return 'Please enter a valid email';
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Please enter your password';
    if (value.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  void _setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }

  String _mapAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Wrong password. Please try again.';
      case 'invalid-email':
        return 'Invalid email address format.';
      case 'invalid-credential':
        return 'Invalid credentials. Check your email and password.';
      default:
        return 'Error: ${e.code}';
    }
  }

  // ── Dispose ────────────────────────────────────────────────────────────────
  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    entranceController.dispose();
    shieldController.dispose();
    super.dispose();
  }
}
