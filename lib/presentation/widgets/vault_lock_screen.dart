import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/error_codes.dart' as auth_error;
import 'package:passwordmanager/presentation/screens/controllers/vault_controller.dart';
import '../../../core/theme/app_theme.dart';

class VaultLockScreen extends StatelessWidget {
  const VaultLockScreen({
    super.key,
    required this.controller,
    required this.onAuthenticated,
    required this.onShowEnrollmentDialog,
    required this.onShowSnackBar,
  });

  final VaultController controller;
  final VoidCallback onAuthenticated;
  final VoidCallback onShowEnrollmentDialog;
  final void Function(String message, {bool isError}) onShowSnackBar;

  Future<void> _handleAuthenticate(BuildContext context) async {
    try {
      final result = await controller.authenticate();
      if (result) {
        onAuthenticated();
      } else {
        onShowSnackBar('Authentication cancelled', isError: true);
      }
    } on PlatformException catch (e) {
      if (e.code == auth_error.notEnrolled) {
        onShowEnrollmentDialog();
      } else if (e.code == auth_error.notAvailable) {
        onShowSnackBar('Biometrics not available on this device.',
            isError: true);
      } else if (e.code == auth_error.lockedOut ||
          e.code == auth_error.permanentlyLockedOut) {
        onShowSnackBar('Too many attempts. Please use your device PIN.',
            isError: true);
      } else {
        onShowSnackBar('Authentication failed: ${e.message}', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;

    return FadeTransition(
      opacity: controller.fadeIn,
      child: SlideTransition(
        position: controller.slideUp,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _LockIcon(controller: controller),
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
                  controller.biometricAvailable
                      ? 'Use biometrics or your device PIN\nto unlock your passwords'
                      : 'Use your device PIN or password\nto unlock your vault',
                  style:
                      TextStyle(fontSize: 14, color: t.textHint, height: 1.5),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                _UnlockButton(
                  controller: controller,
                  onTap: () => controller.isEnrolled
                      ? _handleAuthenticate(context)
                      : onShowEnrollmentDialog(),
                ),
                const SizedBox(height: 20),
                _BiometricHint(controller: controller, t: t),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Lock icon with shake + scale animation ────────────────────────────────────
class _LockIcon extends StatelessWidget {
  const _LockIcon({required this.controller});
  final VaultController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller.lockController,
      builder: (_, child) => Transform.translate(
        offset: Offset(controller.lockShake.value, 0),
        child: Transform.scale(scale: controller.lockScale.value, child: child),
      ),
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
              color: const Color(0xFF1565C0).withValues(alpha: 0.4),
              blurRadius: 32,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: const Icon(Icons.lock_rounded, color: Colors.white, size: 46),
      ),
    );
  }
}

// ── Unlock button ─────────────────────────────────────────────────────────────
class _UnlockButton extends StatelessWidget {
  const _UnlockButton({required this.controller, required this.onTap});
  final VaultController controller;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final authenticating = controller.isAuthenticating;

    return GestureDetector(
      onTap: authenticating ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          gradient: authenticating
              ? LinearGradient(colors: [
                  const Color(0xFF1565C0).withOpacity(0.5),
                  const Color(0xFF6A1B9A).withOpacity(0.5),
                ])
              : const LinearGradient(
                  colors: [Color(0xFF1565C0), Color(0xFF6A1B9A)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: authenticating
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
          child: authenticating
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2.5),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      controller.biometricAvailable
                          ? Icons.fingerprint_rounded
                          : Icons.lock_open_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      controller.biometricAvailable
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
}

// ── Hint below unlock button ──────────────────────────────────────────────────
class _BiometricHint extends StatelessWidget {
  const _BiometricHint({required this.controller, required this.t});
  final VaultController controller;
  final AppThemeExtension t;

  @override
  Widget build(BuildContext context) {
    if (!controller.isEnrolled) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.warning_amber_rounded,
              size: 13, color: const Color(0xFFEF5350).withOpacity(0.8)),
          const SizedBox(width: 6),
          Text('You will be redirected to device settings',
              style: TextStyle(fontSize: 12, color: t.textDisabled)),
        ],
      );
    }
    if (!controller.biometricAvailable) return const SizedBox.shrink();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.info_outline_rounded, size: 13, color: t.textDisabled),
        const SizedBox(width: 6),
        Text('PIN/pattern fallback is also available',
            style: TextStyle(fontSize: 12, color: t.textDisabled)),
      ],
    );
  }
}
