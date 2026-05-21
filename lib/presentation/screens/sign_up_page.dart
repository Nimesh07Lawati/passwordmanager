import 'package:flutter/material.dart';
import 'package:passwordmanager/presentation/screens/controllers/sign_up_page_controller.dart';
import 'package:passwordmanager/presentation/widgets/auth/style_text_field.dart';
import '../../../core/theme/app_theme.dart';
import '../widgets/auth/gradient_button.dart';
import '../widgets/auth/auth_background.dart';
import '../widgets/auth/password_info_row.dart';
import 'home_page.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> with TickerProviderStateMixin {
  late SignUpController _controller;

  @override
  void initState() {
    super.initState();
    _controller = SignUpController(vsync: this);

    // Listen for sign up events
    _controller.addListener(_onControllerUpdate);
  }

  void _onControllerUpdate() {
    final event = _controller.lastEvent;
    if (event != null) {
      if (event.event == SignUpEvent.signUpSuccess) {
        _controller.consumeEvent();
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomePage()),
          );
        }
      } else if (event.event == SignUpEvent.signUpError) {
        _controller.consumeEvent();
        if (mounted && event.errorMessage != null) {
          _showErrorSnackBar(event.errorMessage!);
        }
      }
    }
  }

  void _showErrorSnackBar(String message) {
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

  @override
  void dispose() {
    _controller.removeListener(_onControllerUpdate);
    _controller.dispose();
    super.dispose();
  }

  void _navigateToLogin() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: t.background,
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, child) {
          return Stack(
            children: [
              AuthBackground(
                shieldRotate: _controller.shieldRotate,
                isDark: isDark,
              ),
              SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: FadeTransition(
                      opacity: _controller.fadeIn,
                      child: SlideTransition(
                        position: _controller.slideUp,
                        child: Form(
                          key: _controller.formKey,
                          child: Column(
                            children: [
                              const SizedBox(height: 60),
                              _buildHeader(t),
                              const SizedBox(height: 40),
                              _buildEmailField(t),
                              const SizedBox(height: 14),
                              _buildPasswordField(t),
                              const SizedBox(height: 14),
                              _buildConfirmPasswordField(t),
                              const SizedBox(height: 10),
                              PasswordInfoRow(theme: t),
                              const SizedBox(height: 20),
                              _buildSignUpButton(),
                              const SizedBox(height: 28),
                              _buildDivider(t),
                              const SizedBox(height: 24),
                              _buildLoginLink(),
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
          );
        },
      ),
    );
  }

  Widget _buildHeader(AppThemeExtension t) {
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
                color: const Color(0xFF1565C0).withValues(alpha: 0.45),
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
          'Create Account',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: t.textPrimary,
            letterSpacing: -0.6,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Sign up to secure your passwords',
          style: TextStyle(
            fontSize: 14,
            color: t.textHint,
            fontWeight: FontWeight.w400,
            letterSpacing: 0.1,
          ),
        ),
      ],
    );
  }

  Widget _buildEmailField(AppThemeExtension t) {
    return StyledTextField(
      controller: _controller.emailController,
      label: 'Email address',
      prefixIcon: Icons.alternate_email_rounded,
      keyboardType: TextInputType.emailAddress,
      theme: t,
      validator: _controller.validateEmail,
    );
  }

  Widget _buildPasswordField(AppThemeExtension t) {
    return StyledTextField(
      controller: _controller.passwordController,
      label: 'Master password',
      prefixIcon: Icons.lock_outline_rounded,
      obscureText: !_controller.isPasswordVisible,
      theme: t,
      suffixIcon: GestureDetector(
        onTap: _controller.togglePasswordVisibility,
        child: Icon(
          _controller.isPasswordVisible
              ? Icons.visibility_rounded
              : Icons.visibility_off_rounded,
          color: t.textHint,
          size: 20,
        ),
      ),
      validator: _controller.validatePassword,
    );
  }

  Widget _buildConfirmPasswordField(AppThemeExtension t) {
    return StyledTextField(
      controller: _controller.confirmPasswordController,
      label: 'Confirm password',
      prefixIcon: Icons.lock_outline_rounded,
      obscureText: !_controller.isConfirmPasswordVisible,
      theme: t,
      suffixIcon: GestureDetector(
        onTap: _controller.toggleConfirmPasswordVisibility,
        child: Icon(
          _controller.isConfirmPasswordVisible
              ? Icons.visibility_rounded
              : Icons.visibility_off_rounded,
          color: t.textHint,
          size: 20,
        ),
      ),
      validator: _controller.validateConfirmPassword,
    );
  }

  Widget _buildSignUpButton() {
    return GradientButton(
      onTap: _controller.isLoading ? null : _controller.signUp,
      isLoading: _controller.isLoading,
      label: 'Create Account',
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

  Widget _buildLoginLink() {
    return GestureDetector(
      onTap: _navigateToLogin,
      child: RichText(
        text: TextSpan(
          text: "Already have an account? ",
          style: TextStyle(
            fontSize: 14,
            color: context.appTheme.textSecondary,
            fontWeight: FontWeight.w400,
          ),
          children: const [
            TextSpan(
              text: 'Sign In',
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
