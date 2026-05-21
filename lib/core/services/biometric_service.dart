import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth/error_codes.dart' as auth_error;
import 'package:app_settings/app_settings.dart';

enum BiometricStatus {
  available,
  notSupported,
  notEnrolled,
  lockedOut,
}

class BiometricService {
  BiometricService._();
  static final BiometricService instance = BiometricService._();

  final LocalAuthentication _localAuth = LocalAuthentication();

  // ── Availability ───────────────────────────────────────────────────────────

  /// Returns the current biometric status of the device.
  Future<BiometricStatus> getStatus() async {
    try {
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      if (!isDeviceSupported) return BiometricStatus.notSupported;

      final canCheckBiometrics = await _localAuth.canCheckBiometrics;
      final enrolled = await _localAuth.getAvailableBiometrics();
      if (!canCheckBiometrics || enrolled.isEmpty) {
        return BiometricStatus.notEnrolled;
      }

      return BiometricStatus.available;
    } catch (_) {
      return BiometricStatus.notSupported;
    }
  }

  /// Convenience getters built on [getStatus] — use these to keep
  /// call-sites readable without repeating the switch everywhere.
  Future<bool> get isAvailable async =>
      await getStatus() == BiometricStatus.available;

  Future<bool> get isEnrolled async {
    final s = await getStatus();
    return s == BiometricStatus.available;
  }

  // ── Authentication ─────────────────────────────────────────────────────────

  /// Triggers biometric / device-PIN prompt with [reason].
  ///
  /// Returns an [AuthResult] instead of throwing so callers never need
  /// a try-catch — just check [AuthResult.success] and act on
  /// [AuthResult.status] when it failed.
  Future<AuthResult> authenticate({required String reason}) async {
    final status = await getStatus();

    if (status == BiometricStatus.notSupported) {
      return AuthResult._(
        success: false,
        status: status,
        errorMessage: 'Device does not support authentication',
      );
    }

    if (status == BiometricStatus.notEnrolled) {
      return AuthResult._(
        success: false,
        status: status,
        errorMessage: 'No biometrics enrolled',
      );
    }

    try {
      final result = await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: false, // allow PIN fallback
          stickyAuth: true,
        ),
      );

      return AuthResult._(
        success: result,
        status:
            result ? BiometricStatus.available : BiometricStatus.notEnrolled,
      );
    } on PlatformException catch (e) {
      if (e.code == auth_error.lockedOut ||
          e.code == auth_error.permanentlyLockedOut) {
        return AuthResult._(
          success: false,
          status: BiometricStatus.lockedOut,
          errorMessage: 'Too many attempts. Try again later.',
        );
      }
      if (e.code == auth_error.notEnrolled) {
        return AuthResult._(
          success: false,
          status: BiometricStatus.notEnrolled,
          errorMessage: 'No biometrics enrolled',
        );
      }
      return AuthResult._(
        success: false,
        status: BiometricStatus.notSupported,
        errorMessage: e.message ?? 'Authentication error',
      );
    }
  }

  // ── Settings ───────────────────────────────────────────────────────────────

  Future<void> openSecuritySettings() async {
    await AppSettings.openAppSettings(type: AppSettingsType.security);
  }
}

// ── Result type ───────────────────────────────────────────────────────────────

class AuthResult {
  const AuthResult._({
    required this.success,
    required this.status,
    this.errorMessage,
  });

  final bool success;
  final BiometricStatus status;

  /// Non-null only when [success] is false.
  final String? errorMessage;

  bool get needsEnrollment => status == BiometricStatus.notEnrolled;
  bool get isLockedOut => status == BiometricStatus.lockedOut;
}
