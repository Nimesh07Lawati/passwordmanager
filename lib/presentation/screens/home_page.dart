import 'package:passwordmanager/presentation/screens/controllers/home_controller.dart';
import 'package:passwordmanager/presentation/widgets/auth_background.dart';
import 'package:passwordmanager/presentation/widgets/gradient_button.dart';
import 'package:passwordmanager/presentation/widgets/app_input_field.dart';
import 'login_page.dart';
import 'vault_page.dart';
import 'package:passwordmanager/core/extension/import_extensios.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late final HomeController _controller;

  @override
  void initState() {
    super.initState();
    _controller = HomeController(vsync: this);
    _controller.addListener(_onControllerUpdate);
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerUpdate);
    _controller.dispose();
    super.dispose();
  }

  // ── Event handling ─────────────────────────────────────────────────────────

  void _onControllerUpdate() {
    final event = _controller.lastEvent;
    if (event == null) return;
    _controller.consumeEvent();

    switch (event.event) {
      case HomeEvent.saveSuccess:
        if (event.errorMessage != null) {
          _showSnackBar(event.errorMessage!, isError: true);
        } else {
          _showSnackBar('Password encrypted and saved');
        }
      case HomeEvent.needsEnrollment:
        _showEnrollmentDialog();
      case HomeEvent.needsMasterPassword:
        _showNeedsMasterPasswordDialog();
      case HomeEvent.logoutRequested:
        _showLogoutDialog();
    }
  }

  // ── Navigation ─────────────────────────────────────────────────────────────

  void _navigateToVault() {
    Navigator.push(
        context, MaterialPageRoute(builder: (_) => const VaultPage()));
  }

  Future<void> _logout() async {
    await _controller.logout();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  // ── Dialogs ────────────────────────────────────────────────────────────────

  void _showEnrollmentDialog() {
    if (!mounted) return;
    final t = context.appTheme;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: t.surfaceHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1565C0), Color(0xFF6A1B9A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.fingerprint_rounded,
                  color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Set Up Biometrics',
                style: TextStyle(
                    color: t.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Biometric or screen lock is required to save passwords securely.',
              style: TextStyle(
                  color: t.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 10),
            Text(
              'Please set up fingerprint, face unlock, or a PIN in your device security settings.',
              style:
                  TextStyle(color: t.textSecondary, fontSize: 13, height: 1.5),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Not Now',
                style: TextStyle(
                    color: t.textDisabled, fontWeight: FontWeight.w600)),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFF1565C0), Color(0xFF6A1B9A)]),
              borderRadius: BorderRadius.circular(10),
            ),
            child: TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await BiometricService.instance.openSecuritySettings();
              },
              child: const Text('Open Settings',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  /// Shown when the user tries to save a password but no vault key is
  /// cached locally yet (fresh install / new device — they haven't been
  /// through the master-password setup or recovery flow in VaultPage
  /// yet). Sends them there; their in-progress form is left untouched
  /// so they can come straight back and hit save again afterward.
  void _showNeedsMasterPasswordDialog() {
    if (!mounted) return;
    final t = context.appTheme;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: t.surfaceHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1565C0), Color(0xFF6A1B9A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.vpn_key_rounded,
                  color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Vault Setup Needed',
                style: TextStyle(
                    color: t.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        content: Text(
          'Before saving passwords, open your vault once to set up (or '
          're-enter) your master password. Your details here won\'t be lost.',
          style: TextStyle(color: t.textSecondary, fontSize: 13, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Not Now',
                style: TextStyle(
                    color: t.textDisabled, fontWeight: FontWeight.w600)),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFF1565C0), Color(0xFF6A1B9A)]),
              borderRadius: BorderRadius.circular(10),
            ),
            child: TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                _navigateToVault();
              },
              child: const Text('Open Vault',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    final t = context.appTheme;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: t.surfaceHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1565C0), Color(0xFF6A1B9A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.logout_rounded,
                  color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            Text(
              'Sign Out',
              style: TextStyle(
                  color: t.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to sign out of your vault?',
          style: TextStyle(color: t.textSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: TextStyle(
                    color: t.textDisabled, fontWeight: FontWeight.w600)),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFF1565C0), Color(0xFF6A1B9A)]),
              borderRadius: BorderRadius.circular(10),
            ),
            child: TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                _logout();
              },
              child: const Text('Sign Out',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Snackbar ───────────────────────────────────────────────────────────────

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError
                  ? Icons.error_outline_rounded
                  : Icons.check_circle_outline_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor:
            isError ? const Color(0xFFEF5350) : const Color(0xFF1565C0),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = FirebaseAuth.instance.currentUser;

    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) => Scaffold(
        backgroundColor: t.background,
        body: Stack(
          children: [
            AuthBackground(
                shieldRotate: _controller.shieldRotate, isDark: isDark),
            SafeArea(
              child: Column(
                children: [
                  _buildAppBar(t, user),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: FadeTransition(
                        opacity: _controller.fadeIn,
                        child: SlideTransition(
                          position: _controller.slideUp,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 8),
                              _buildVaultBanner(t, user),
                              const SizedBox(height: 28),
                              _buildSectionHeader(
                                t,
                                'Add New Password',
                                Icons.add_circle_outline_rounded,
                              ),
                              const SizedBox(height: 6),
                              _buildBiometricHint(t),
                              const SizedBox(height: 14),
                              _buildAddPasswordCard(t),
                              const SizedBox(height: 40),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(AppThemeExtension t, User? user) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1565C0), Color(0xFF6A1B9A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1565C0).withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child:
                const Icon(Icons.shield_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PassGuard',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: t.textPrimary,
                    letterSpacing: -0.4,
                  ),
                ),
                if (user?.email != null)
                  Text(
                    user!.email!,
                    style: TextStyle(
                        fontSize: 11,
                        color: t.textHint,
                        fontWeight: FontWeight.w400),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          GestureDetector(
            onTap:
                _controller.requestLogout, // ← controller, not dialog directly
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: t.surfaceHigh,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: t.borderColor, width: 1),
              ),
              child: Icon(Icons.logout_rounded, color: t.textHint, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVaultBanner(AppThemeExtension t, User? user) {
    return GestureDetector(
      onTap: _navigateToVault,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1565C0), Color(0xFF6A1B9A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1565C0).withValues(alpha: 0.38),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child:
                  const Icon(Icons.lock_rounded, color: Colors.white, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'My Password Vault',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _buildPasswordCount(user),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: const [
                  Icon(Icons.fingerprint_rounded,
                      color: Colors.white, size: 16),
                  SizedBox(width: 6),
                  Text(
                    'Open',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordCount(User? user) {
    if (user == null) {
      return const Text(
        'Tap to unlock your vault',
        style: TextStyle(
            color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w400),
      );
    }
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('passwords')
          .snapshots(),
      builder: (context, snapshot) {
        final count = snapshot.data?.docs.length ?? 0;
        return Text(
          count == 0
              ? 'No passwords saved yet'
              : '$count password${count == 1 ? '' : 's'} · biometric protected',
          style: const TextStyle(
              color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w400),
        );
      },
    );
  }

  Widget _buildSectionHeader(AppThemeExtension t, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF1565C0)),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: t.textPrimary,
              letterSpacing: -0.2),
        ),
      ],
    );
  }

  Widget _buildBiometricHint(AppThemeExtension t) {
    return Row(
      children: [
        Icon(Icons.fingerprint_rounded, size: 13, color: t.textHint),
        const SizedBox(width: 6),
        Text(
          'Biometric verification required to save',
          style: TextStyle(
              fontSize: 12, color: t.textHint, fontWeight: FontWeight.w400),
        ),
      ],
    );
  }

  Widget _buildAddPasswordCard(AppThemeExtension t) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: t.surfaceHigh,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: t.borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Form(
        key: _controller.formKey,
        child: Column(
          children: [
            AppInputField(
              controller: _controller.siteController,
              label: 'Site name',
              prefixIcon: Icons.language_rounded,
              theme: t,
              validator: (v) => _controller.validateRequired(v, 'site name'),
            ),
            const SizedBox(height: 14),
            AppInputField(
              controller: _controller.usernameController,
              label: 'Username / Email',
              prefixIcon: Icons.alternate_email_rounded,
              keyboardType: TextInputType.emailAddress,
              theme: t,
              validator: (v) =>
                  _controller.validateRequired(v, 'username or email'),
            ),
            const SizedBox(height: 14),
            AppInputField(
              controller: _controller.passwordController,
              label: 'Password',
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
              validator: (v) => _controller.validateRequired(v, 'password'),
            ),
            const SizedBox(height: 20),
            GradientButton(
              onTap: _controller.isLoading ? null : _controller.savePassword,
              isLoading: _controller.isLoading,
              label: 'Save Password Securely',
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_rounded,
                    size: 11,
                    color: const Color(0xFF1565C0).withValues(alpha: 0.6)),
                const SizedBox(width: 5),
                Text(
                  'AES-256 encrypted · biometric protected',
                  style: TextStyle(
                      fontSize: 11,
                      color: const Color(0xFF1565C0).withValues(alpha: 0.6),
                      fontWeight: FontWeight.w400),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
