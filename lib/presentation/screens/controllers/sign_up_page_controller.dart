import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ── Events ─────────────────────────────────────────────────────────────────

enum SignUpEvent {
  signUpSuccess,
  signUpError,
}

class SignUpEventPayload {
  const SignUpEventPayload(this.event, {this.errorMessage});
  final SignUpEvent event;
  final String? errorMessage;
}

// ── Controller ─────────────────────────────────────────────────────────────

class SignUpController with ChangeNotifier {
  SignUpController({required TickerProvider vsync}) {
    _initAnimations(vsync);
  }

  // ── Form ───────────────────────────────────────────────────────────────────
  final formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  // ── UI state ───────────────────────────────────────────────────────────────
  bool isLoading = false;
  bool isPasswordVisible = false;
  bool isConfirmPasswordVisible = false;

  // ── Event ──────────────────────────────────────────────────────────────────
  SignUpEventPayload? _lastEvent;
  SignUpEventPayload? get lastEvent => _lastEvent;

  void _emit(SignUpEvent event, {String? errorMessage}) {
    _lastEvent = SignUpEventPayload(event, errorMessage: errorMessage);
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

  void toggleConfirmPasswordVisibility() {
    isConfirmPasswordVisible = !isConfirmPasswordVisible;
    notifyListeners();
  }

  // ── Sign Up ─────────────────────────────────────────────────────────────────
  Future<void> signUp() async {
    if (!formKey.currentState!.validate()) return;

    _setLoading(true);

    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      _emit(SignUpEvent.signUpSuccess);
    } on FirebaseAuthException catch (e) {
      _emit(SignUpEvent.signUpError, errorMessage: _mapAuthError(e));
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

  String? validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) return 'Please confirm your password';
    if (value != passwordController.text) return 'Passwords do not match';
    return null;
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  void _setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }

  String _mapAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'This email is already registered';
      case 'weak-password':
        return 'Password is too weak';
      case 'invalid-email':
        return 'Invalid email address';
      default:
        return 'Error: ${e.code}';
    }
  }

  // ── Dispose ────────────────────────────────────────────────────────────────
  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    entranceController.dispose();
    shieldController.dispose();
    super.dispose();
  }
}
