import 'package:passwordmanager/core/extension/import_extensios.dart';
import 'package:passwordmanager/presentation/screens/controllers/login_controller.dart';
import 'package:passwordmanager/presentation/widgets/app_input_field.dart';
import '../widgets/gradient_button.dart';
import '../widgets/auth_background.dart';
import 'sign_up_page.dart';
import 'home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  late LoginController _controller;

  @override
  void initState() {
    super.initState();
    _controller = LoginController(vsync: this);

    // Listen for login success
    _controller.addListener(_onControllerUpdate);
  }

  void _onControllerUpdate() {
    final event = _controller.lastEvent;

    if (event != null) {
      if (event.event == LoginEvent.loginSuccess) {
        _controller.consumeEvent();

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const HomePage(),
            ),
          );
        }
      } else if (event.event == LoginEvent.loginError) {
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
            const Icon(
              Icons.error_outline_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(message),
            ),
          ],
        ),
        backgroundColor: Colors.red.shade400,
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

  void _navigateToSignUp() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const SignUpPage(),
      ),
    );
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
              // Background
              AuthBackground(
                shieldRotate: _controller.shieldRotate,
                isDark: isDark,
              ),

              // Shield Logo
              Positioned(
                top: 113,
                left: 0,
                right: 0,
                child: Center(
                  child: _buildShieldLogo(),
                ),
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
                              const SizedBox(height: 250),
                              _buildTitles(t),
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
          );
        },
      ),
    );
  }

  Widget _buildShieldLogo() {
    return Container(
      width: 84,
      height: 84,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.secondary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.45),
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
    );
  }

  Widget _buildTitles(AppThemeExtension t) {
    return Column(
      children: [
        Text(
          'Welcome Back',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: t.textPrimary,
            letterSpacing: -0.6,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Sign in to access your vault',
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
    return AppInputField(
      controller: _controller.emailController,
      label: 'Email address',
      prefixIcon: Icons.alternate_email_rounded,
      keyboardType: TextInputType.emailAddress,
      theme: t,
      validator: _controller.validateEmail,
    );
  }

  Widget _buildPasswordField(AppThemeExtension t) {
    return AppInputField(
      controller: _controller.passwordController,
      label: 'password',
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

  Widget _buildForgotPassword() {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: () {},
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            vertical: 8,
            horizontal: 4,
          ),
        ),
        child: const Text(
          'Forgot password?',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return GradientButton(
      onTap: _controller.isLoading ? null : _controller.login,
      isLoading: _controller.isLoading,
      label: 'Sign In',
    );
  }

  Widget _buildDivider(AppThemeExtension t) {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: t.borderColor,
            thickness: 1,
          ),
        ),
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
        Expanded(
          child: Divider(
            color: t.borderColor,
            thickness: 1,
          ),
        ),
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
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
