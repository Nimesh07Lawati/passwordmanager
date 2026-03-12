import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth/error_codes.dart' as auth_error;
import 'package:app_settings/app_settings.dart';
import '../../../core/theme/app_theme.dart';
import '../widgets/auth/auth_background.dart';

class VaultPage extends StatefulWidget {
  const VaultPage({super.key});

  @override
  State<VaultPage> createState() => _VaultPageState();
}

class _VaultPageState extends State<VaultPage> with TickerProviderStateMixin {
  final LocalAuthentication _localAuth = LocalAuthentication();

  bool _isAuthenticated = false;
  bool _isAuthenticating = false;
  bool _biometricAvailable = false;
  bool _isEnrolled = true;
  String _searchQuery = '';
  final _searchController = TextEditingController();

  late AnimationController _shieldController;
  late AnimationController _entranceController;
  late AnimationController _lockController;
  late Animation<double> _shieldRotate;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;
  late Animation<double> _lockScale;
  late Animation<double> _lockShake;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _checkBiometricAvailability();
  }

  void _initAnimations() {
    _shieldController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();

    _lockController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _shieldRotate = Tween<double>(begin: 0, end: 2 * math.pi).animate(
      CurvedAnimation(parent: _shieldController, curve: Curves.linear),
    );

    _fadeIn = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
    );

    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.1, 1.0, curve: Curves.easeOutCubic),
    ));

    _lockScale = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.15), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.15, end: 1.0), weight: 50),
    ]).animate(
        CurvedAnimation(parent: _lockController, curve: Curves.easeInOut));

    _lockShake = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -8.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: -8.0, end: 8.0), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 8.0, end: -4.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: -4.0, end: 0.0), weight: 20),
    ]).animate(
        CurvedAnimation(parent: _lockController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _shieldController.dispose();
    _entranceController.dispose();
    _lockController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _checkBiometricAvailability() async {
    try {
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      final canCheckBiometrics = await _localAuth.canCheckBiometrics;
      final enrolledBiometrics = await _localAuth.getAvailableBiometrics();

      setState(() {
        _biometricAvailable = isDeviceSupported;
        // Device supports it but user has not enrolled any biometric or PIN
        _isEnrolled = canCheckBiometrics && enrolledBiometrics.isNotEmpty;
      });
    } catch (_) {
      setState(() {
        _biometricAvailable = false;
        _isEnrolled = false;
      });
    }
  }

  Future<void> _authenticate() async {
    if (_isAuthenticating) return;
    setState(() => _isAuthenticating = true);
    _lockController.forward(from: 0);

    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Authenticate to view your saved passwords',
        options: const AuthenticationOptions(
          biometricOnly: false, // fallback to PIN/pattern if needed
          stickyAuth: true,
        ),
      );

      if (mounted) {
        if (authenticated) {
          setState(() => _isAuthenticated = true);
          // Re-run entrance animation for the vault content
          _entranceController.forward(from: 0);
        } else {
          _showSnackBar('Authentication cancelled', isError: true);
        }
      }
    } on PlatformException catch (e) {
      if (e.code == auth_error.notEnrolled) {
        if (mounted) {
          setState(() => _isEnrolled = false);
          _showEnrollmentDialog();
        }
      } else if (e.code == auth_error.notAvailable) {
        if (mounted)
          _showSnackBar('Biometrics not available on this device.',
              isError: true);
      } else if (e.code == auth_error.lockedOut ||
          e.code == auth_error.permanentlyLockedOut) {
        if (mounted)
          _showSnackBar('Too many attempts. Please use your device PIN.',
              isError: true);
      } else {
        if (mounted)
          _showSnackBar('Authentication failed: ${e.message}', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isAuthenticating = false);
    }
  }

  void _lockVault() {
    setState(() => _isAuthenticated = false);
    _entranceController.forward(from: 0);
  }

  void _showEnrollmentDialog() {
    final t = context.appTheme;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
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
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'No biometrics or screen lock found on this device.',
              style: TextStyle(
                color: t.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'To protect your passwords, please set up fingerprint, face unlock, or a PIN in your device security settings.',
              style: TextStyle(
                color: t.textSecondary,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Not Now',
              style:
                  TextStyle(color: t.textDisabled, fontWeight: FontWeight.w600),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1565C0), Color(0xFF6A1B9A)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: TextButton(
              onPressed: () {
                Navigator.pop(context);
                _openSecuritySettings();
              },
              child: const Text(
                'Open Settings',
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openSecuritySettings() async {
    try {
      await AppSettings.openAppSettings(type: AppSettingsType.security);
    } catch (_) {
      // Fallback: open general device settings if security settings unavailable
      if (mounted) {
        _showSnackBar(
          'Please go to Settings → Security to set up biometrics',
          isError: false,
        );
      }
    }
  }

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

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    _showSnackBar('$label copied to clipboard');
  }

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: t.background,
      body: Stack(
        children: [
          AuthBackground(shieldRotate: _shieldRotate, isDark: isDark),
          SafeArea(
            child: _isAuthenticated ? _buildVault(t) : _buildLockScreen(t),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // LOCK SCREEN
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildLockScreen(AppThemeExtension t) {
    return FadeTransition(
      opacity: _fadeIn,
      child: SlideTransition(
        position: _slideUp,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLockIcon(t),
                const SizedBox(height: 32),
                Text(
                  'Vault Locked',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: t.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _biometricAvailable
                      ? 'Use biometrics or your device PIN\nto unlock your passwords'
                      : 'Use your device PIN or password\nto unlock your vault',
                  style: TextStyle(
                    fontSize: 14,
                    color: t.textHint,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                _buildUnlockButton(t),
                const SizedBox(height: 20),
                _buildBiometricHint(t),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLockIcon(AppThemeExtension t) {
    return AnimatedBuilder(
      animation: _lockController,
      builder: (_, child) {
        return Transform.translate(
          offset: Offset(_lockShake.value, 0),
          child: Transform.scale(
            scale: _lockScale.value,
            child: child,
          ),
        );
      },
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1565C0), Color(0xFF6A1B9A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1565C0).withOpacity(0.4),
              blurRadius: 32,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: const Icon(
          Icons.lock_rounded,
          color: Colors.white,
          size: 46,
        ),
      ),
    );
  }

  Widget _buildUnlockButton(AppThemeExtension t) {
    return GestureDetector(
      onTap: _isAuthenticating
          ? null
          : (_isEnrolled ? _authenticate : _showEnrollmentDialog),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          gradient: _isAuthenticating
              ? LinearGradient(
                  colors: [
                    const Color(0xFF1565C0).withOpacity(0.5),
                    const Color(0xFF6A1B9A).withOpacity(0.5),
                  ],
                )
              : const LinearGradient(
                  colors: [Color(0xFF1565C0), Color(0xFF6A1B9A)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: _isAuthenticating
              ? []
              : [
                  BoxShadow(
                    color: const Color(0xFF1565C0).withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
        ),
        child: Center(
          child: _isAuthenticating
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _biometricAvailable
                          ? Icons.fingerprint_rounded
                          : Icons.lock_open_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _biometricAvailable
                          ? 'Unlock with Biometrics'
                          : 'Unlock Vault',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildBiometricHint(AppThemeExtension t) {
    if (!_isEnrolled) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.warning_amber_rounded,
              size: 13, color: const Color(0xFFEF5350).withOpacity(0.8)),
          const SizedBox(width: 6),
          Text(
            'You will be redirected to device settings',
            style: TextStyle(fontSize: 12, color: t.textDisabled),
          ),
        ],
      );
    }
    if (!_biometricAvailable) return const SizedBox.shrink();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.info_outline_rounded, size: 13, color: t.textDisabled),
        const SizedBox(width: 6),
        Text(
          'PIN/pattern fallback is also available',
          style: TextStyle(fontSize: 12, color: t.textDisabled),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // VAULT CONTENT
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildVault(AppThemeExtension t) {
    return FadeTransition(
      opacity: _fadeIn,
      child: SlideTransition(
        position: _slideUp,
        child: Column(
          children: [
            _buildVaultAppBar(t),
            _buildSearchBar(t),
            Expanded(child: _buildPasswordList(t)),
          ],
        ),
      ),
    );
  }

  Widget _buildVaultAppBar(AppThemeExtension t) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
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
                  color: const Color(0xFF1565C0).withOpacity(0.35),
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
                  'My Vault',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: t.textPrimary,
                    letterSpacing: -0.4,
                  ),
                ),
                Text(
                  'Unlocked',
                  style: TextStyle(
                    fontSize: 11,
                    color: t.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          // Lock button
          GestureDetector(
            onTap: _lockVault,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: t.surfaceHigh,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: t.borderColor, width: 1),
              ),
              child: Icon(Icons.lock_rounded, color: t.textHint, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(AppThemeExtension t) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: t.surfaceHigh,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: t.borderColor, width: 1),
        ),
        child: Row(
          children: [
            const SizedBox(width: 14),
            Icon(Icons.search_rounded, color: t.textHint, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _searchController,
                onChanged: (v) =>
                    setState(() => _searchQuery = v.toLowerCase()),
                style: TextStyle(
                  color: t.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: 'Search passwords...',
                  hintStyle: TextStyle(color: t.textHint, fontSize: 14),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            if (_searchQuery.isNotEmpty)
              GestureDetector(
                onTap: () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                },
                child: Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Icon(Icons.close_rounded, color: t.textHint, size: 18),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordList(AppThemeExtension t) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox.shrink();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('passwords')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: const AlwaysStoppedAnimation(Color(0xFF1565C0)),
              ),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState(t);
        }

        final docs = snapshot.data!.docs.where((doc) {
          if (_searchQuery.isEmpty) return true;
          final data = doc.data() as Map<String, dynamic>;
          final site = (data['siteName'] ?? '').toString().toLowerCase();
          final user = (data['user_name'] ?? '').toString().toLowerCase();
          return site.contains(_searchQuery) || user.contains(_searchQuery);
        }).toList();

        if (docs.isEmpty) {
          return _buildNoResultsState(t);
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
          itemCount: docs.length,
          itemBuilder: (_, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            return _buildPasswordTile(t, data, docs[i].id, user.uid);
          },
        );
      },
    );
  }

  Widget _buildPasswordTile(
    AppThemeExtension t,
    Map<String, dynamic> data,
    String docId,
    String uid,
  ) {
    final siteName = data['siteName'] ?? '';
    final username = data['user_name'] ?? '';
    final password = data['password'] ?? '';
    final initial = siteName.isNotEmpty ? siteName[0].toUpperCase() : '?';

    // Deterministic color per site initial
    final colors = [
      [const Color(0xFF1565C0), const Color(0xFF6A1B9A)],
      [const Color(0xFF00838F), const Color(0xFF1565C0)],
      [const Color(0xFF6A1B9A), const Color(0xFFAD1457)],
      [const Color(0xFF2E7D32), const Color(0xFF00838F)],
      [const Color(0xFFE65100), const Color(0xFF6A1B9A)],
    ];
    final colorPair = colors[initial.codeUnitAt(0) % colors.length];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: t.surfaceHigh,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: t.borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: colorPair,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                initial,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          title: Text(
            siteName,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: t.textPrimary,
              letterSpacing: -0.2,
            ),
          ),
          subtitle: Text(
            username,
            style: TextStyle(fontSize: 12, color: t.textHint),
            overflow: TextOverflow.ellipsis,
          ),
          iconColor: t.textHint,
          collapsedIconColor: t.textHint,
          children: [
            // Divider
            Divider(color: t.borderColor, thickness: 1, height: 1),
            const SizedBox(height: 14),

            // Username row
            _buildDetailRow(
              t,
              label: 'Username',
              value: username,
              icon: Icons.alternate_email_rounded,
              onCopy: () => _copyToClipboard(username, 'Username'),
            ),
            const SizedBox(height: 10),

            // Password row
            _buildPasswordRow(t, password),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    AppThemeExtension t, {
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onCopy,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: t.surfaceMedium,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF1565C0)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: t.textDisabled,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    color: t.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onCopy,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF1565C0).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.copy_rounded,
                size: 14,
                color: Color(0xFF1565C0),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordRow(AppThemeExtension t, String password) {
    return StatefulBuilder(
      builder: (context, setLocal) {
        bool visible = false;
        return StatefulBuilder(
          builder: (context, setInner) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: t.surfaceMedium,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lock_outline_rounded,
                      size: 16, color: Color(0xFF6A1B9A)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PASSWORD',
                          style: TextStyle(
                            fontSize: 10,
                            color: t.textDisabled,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          visible ? password : '••••••••••••',
                          style: TextStyle(
                            fontSize: 13,
                            color: t.textPrimary,
                            fontWeight: FontWeight.w500,
                            letterSpacing: visible ? 0 : 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Toggle visibility
                  GestureDetector(
                    onTap: () => setInner(() => visible = !visible),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6A1B9A).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        visible
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded,
                        size: 14,
                        color: const Color(0xFF6A1B9A),
                      ),
                    ),
                  ),
                  // Copy
                  GestureDetector(
                    onTap: () => _copyToClipboard(password, 'Password'),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1565C0).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.copy_rounded,
                        size: 14,
                        color: Color(0xFF1565C0),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState(AppThemeExtension t) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF1565C0).withOpacity(0.1),
                    const Color(0xFF6A1B9A).withOpacity(0.1),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.lock_open_rounded,
                size: 36,
                color: const Color(0xFF1565C0).withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No passwords saved yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: t.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add passwords from the home screen\nand they will appear here',
              style: TextStyle(fontSize: 13, color: t.textHint, height: 1.5),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResultsState(AppThemeExtension t) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 40, color: t.textDisabled),
          const SizedBox(height: 14),
          Text(
            'No results for "$_searchQuery"',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: t.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
