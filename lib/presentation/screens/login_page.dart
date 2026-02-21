import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:passwordmanager/presentation/widgets/auth/style_text_field.dart';
import '../../../core/theme/app_theme.dart';
import '../widgets/auth/gradient_button.dart';
import '../widgets/auth/auth_background.dart';
import 'sign_up_page.dart';
import 'home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _auth = FirebaseAuth.instance;

  bool _isLoading = false;
  bool _isPasswordVisible = false;

  late AnimationController _entranceController;
  late AnimationController _shieldController;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;
  late Animation<double> _shieldRotate;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _entranceController.forward();
  }

  void _initializeAnimations() {
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _shieldController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _fadeIn = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
    );

    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.1, 1.0, curve: Curves.easeOutCubic),
    ));

    _shieldRotate = Tween<double>(begin: 0, end: 2 * math.pi).animate(
      CurvedAnimation(parent: _shieldController, curve: Curves.linear),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _entranceController.dispose();
    _shieldController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      final user = userCredential.user;

      if (user != null) {
        // Create user document if not exists
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

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
      }
    } on FirebaseAuthException catch (e) {
      _handleAuthError(e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleAuthError(FirebaseAuthException e) {
    String message = 'An error occurred';
    switch (e.code) {
      case 'user-not-found':
        message = 'No user found with this email.';
        break;
      case 'wrong-password':
        message = 'Wrong password. Please try again.';
        break;
      case 'invalid-email':
        message = 'Invalid email address format.';
        break;
      case 'invalid-credential':
        message = 'Invalid credentials. Check your email and password.';
        break;
      default:
        message = 'Error: ${e.code}';
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline_rounded,
                  color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: const Color(0xFFEF5350),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _navigateToSignUp() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SignUpPage()),
    );
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'Please enter your email';
    if (!value.contains('@')) return 'Please enter a valid email';
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Please enter your password';
    if (value.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: t.background,
      body: Stack(
        children: [
          AuthBackground(
            shieldRotate: _shieldRotate,
            isDark: isDark,
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: FadeTransition(
                  opacity: _fadeIn,
                  child: SlideTransition(
                    position: _slideUp,
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          const SizedBox(height: 60),
                          _buildHeader(),
                          const SizedBox(height: 40),
                          _buildEmailField(t),
                          const SizedBox(height: 14),
                          _buildPasswordField(t),
                          _buildForgotPassword(),
                          const SizedBox(height: 10),
                          _buildLoginButton(),
                          const SizedBox(height: 28),
                          _buildDivider(t),
                          const SizedBox(height: 24),
                          _buildSignUpLink(),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 84,
          height: 84,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1565C0), Color(0xFF6A1B9A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1565C0).withOpacity(0.45),
                blurRadius: 28,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(
            Icons.shield_rounded,
            color: Colors.white,
            size: 40,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Welcome Back',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: context.appTheme.textPrimary,
            letterSpacing: -0.6,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Sign in to access your vault',
          style: TextStyle(
            fontSize: 14,
            color: context.appTheme.textHint,
            fontWeight: FontWeight.w400,
            letterSpacing: 0.1,
          ),
        ),
      ],
    );
  }

  Widget _buildEmailField(AppThemeExtension t) {
    return StyledTextField(
      controller: _emailController,
      label: 'Email address',
      prefixIcon: Icons.alternate_email_rounded,
      keyboardType: TextInputType.emailAddress,
      theme: t,
      validator: _validateEmail,
    );
  }

  Widget _buildPasswordField(AppThemeExtension t) {
    return StyledTextField(
      controller: _passwordController,
      label: 'Master password',
      prefixIcon: Icons.lock_outline_rounded,
      obscureText: !_isPasswordVisible,
      theme: t,
      suffixIcon: GestureDetector(
        onTap: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
        child: Icon(
          _isPasswordVisible
              ? Icons.visibility_rounded
              : Icons.visibility_off_rounded,
          color: t.textHint,
          size: 20,
        ),
      ),
      validator: _validatePassword,
    );
  }

  Widget _buildForgotPassword() {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: () {},
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        ),
        child: const Text(
          'Forgot password?',
          style: TextStyle(
            fontSize: 12,
            color: Color(0xFF1565C0),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return GradientButton(
      onTap: _isLoading ? null : _login,
      isLoading: _isLoading,
      label: 'Sign In',
    );
  }

  Widget _buildDivider(AppThemeExtension t) {
    return Row(
      children: [
        Expanded(child: Divider(color: t.borderColor, thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            'or',
            style: TextStyle(
              color: t.textDisabled,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(child: Divider(color: t.borderColor, thickness: 1)),
      ],
    );
  }

  Widget _buildSignUpLink() {
    return GestureDetector(
      onTap: _navigateToSignUp,
      child: RichText(
        text: TextSpan(
          text: "Don't have an account? ",
          style: TextStyle(
            fontSize: 14,
            color: context.appTheme.textSecondary,
            fontWeight: FontWeight.w400,
          ),
          children: const [
            TextSpan(
              text: 'Create one',
              style: TextStyle(
                color: Color(0xFF1565C0),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
