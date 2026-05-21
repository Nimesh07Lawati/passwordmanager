import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ── Events ─────────────────────────────────────────────────────────────────

enum AddPasswordEvent {
  saveSuccess,
  saveError,
}

class AddPasswordEventPayload {
  const AddPasswordEventPayload(this.event, {this.errorMessage});
  final AddPasswordEvent event;
  final String? errorMessage;
}

// ── Password Strength ───────────────────────────────────────────────────────

enum PasswordStrength {
  weak('Weak', Colors.red),
  fair('Fair', Colors.orange),
  good('Good', Colors.yellow),
  strong('Strong', Colors.green);

  const PasswordStrength(this.label, this.color);
  final String label;
  final Color color;
}

// ── Controller ─────────────────────────────────────────────────────────────

class AddPasswordController with ChangeNotifier {
  AddPasswordController({required TickerProvider vsync}) {
    _initAnimations(vsync);
  }

  // ── Form ───────────────────────────────────────────────────────────────────
  final formKey = GlobalKey<FormState>();
  final appNameController = TextEditingController();
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final notesController = TextEditingController();

  // ── UI state ───────────────────────────────────────────────────────────────
  bool isLoading = false;
  bool isPasswordVisible = false;
  String? selectedCategory;
  PasswordStrength _passwordStrength = PasswordStrength.weak;
  PasswordStrength get passwordStrength => _passwordStrength;

  // Password requirements tracking
  final Map<String, bool> _passwordRequirements = {
    'length': false,
    'uppercase': false,
    'lowercase': false,
    'numbers': false,
    'special': false,
  };
  Map<String, bool> get passwordRequirements =>
      Map.unmodifiable(_passwordRequirements);

  // Available categories
  static const List<String> availableCategories = [
    'Social',
    'Email',
    'Banking',
    'Shopping',
    'Entertainment',
    'Work',
    'Other',
  ];

  // ── Event ──────────────────────────────────────────────────────────────────
  AddPasswordEventPayload? _lastEvent;
  AddPasswordEventPayload? get lastEvent => _lastEvent;

  void _emit(AddPasswordEvent event, {String? errorMessage}) {
    _lastEvent = AddPasswordEventPayload(event, errorMessage: errorMessage);
    notifyListeners();
  }

  void consumeEvent() => _lastEvent = null;

  // ── Animations ─────────────────────────────────────────────────────────────
  late final AnimationController entranceController;
  late final Animation<double> fadeIn;
  late final Animation<Offset> slideUp;

  void _initAnimations(TickerProvider vsync) {
    entranceController = AnimationController(
      vsync: vsync,
      duration: const Duration(milliseconds: 800),
    )..forward();

    fadeIn = CurvedAnimation(
      parent: entranceController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
    );

    slideUp = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: entranceController,
      curve: const Interval(0.1, 1.0, curve: Curves.easeOutCubic),
    ));
  }

  // ── Password visibility ────────────────────────────────────────────────────
  void togglePasswordVisibility() {
    isPasswordVisible = !isPasswordVisible;
    notifyListeners();
  }

  // ── Password Strength Checker ──────────────────────────────────────────────
  void updatePasswordStrength(String password) {
    // Update requirements
    _passwordRequirements['length'] = password.length >= 8;
    _passwordRequirements['uppercase'] = password.contains(RegExp(r'[A-Z]'));
    _passwordRequirements['lowercase'] = password.contains(RegExp(r'[a-z]'));
    _passwordRequirements['numbers'] = password.contains(RegExp(r'[0-9]'));
    _passwordRequirements['special'] =
        password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

    // Calculate strength
    int score = _passwordRequirements.values.where((v) => v == true).length;

    if (score <= 2) {
      _passwordStrength = PasswordStrength.weak;
    } else if (score == 3) {
      _passwordStrength = PasswordStrength.fair;
    } else if (score == 4) {
      _passwordStrength = PasswordStrength.good;
    } else {
      _passwordStrength = PasswordStrength.strong;
    }

    notifyListeners();
  }

  // Get password strength percentage (0.0 - 1.0)
  double get passwordStrengthPercentage {
    switch (_passwordStrength) {
      case PasswordStrength.weak:
        return 0.25;
      case PasswordStrength.fair:
        return 0.5;
      case PasswordStrength.good:
        return 0.75;
      case PasswordStrength.strong:
        return 1.0;
    }
  }

  // ── Category ───────────────────────────────────────────────────────────────
  void setCategory(String category) {
    selectedCategory = category;
    notifyListeners();
  }

  // ── Save Password ──────────────────────────────────────────────────────────
  Future<void> savePassword() async {
    if (!formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _emit(AddPasswordEvent.saveError, errorMessage: 'User not logged in');
      return;
    }

    _setLoading(true);

    try {
      final passwordData = {
        'appName': appNameController.text.trim(),
        'username': usernameController.text.trim(),
        'password':
            passwordController.text.trim(), // In real app, encrypt this!
        'notes': notesController.text.trim(),
        'category': selectedCategory ?? 'Uncategorized',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'userId': user.uid,
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('passwords')
          .add(passwordData);

      _emit(AddPasswordEvent.saveSuccess);
    } catch (e) {
      _emit(AddPasswordEvent.saveError,
          errorMessage: 'Failed to save password: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // ── Validation ─────────────────────────────────────────────────────────────
  String? validateAppName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter app/website name';
    }
    return null;
  }

  String? validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter username/email';
    }
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a password';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    return null;
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  void _setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }

  void clearForm() {
    appNameController.clear();
    usernameController.clear();
    passwordController.clear();
    notesController.clear();
    selectedCategory = null;
    _passwordStrength = PasswordStrength.weak;
    _passwordRequirements.updateAll((key, value) => false);
    notifyListeners();
  }

  // ── Dispose ────────────────────────────────────────────────────────────────
  @override
  void dispose() {
    appNameController.dispose();
    usernameController.dispose();
    passwordController.dispose();
    notesController.dispose();
    entranceController.dispose();
    super.dispose();
  }
}
