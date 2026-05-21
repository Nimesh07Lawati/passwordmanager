import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth/error_codes.dart' as auth_error;
import 'package:passwordmanager/core/services/encryption_service.dart';
import 'package:passwordmanager/presentation/screens/controllers/vault_controller.dart';
import 'package:passwordmanager/presentation/widgets/vault_widgets/password_title_card.dart';
import 'package:passwordmanager/presentation/widgets/vault_widgets/vault_app_bar.dart';
import 'package:passwordmanager/presentation/widgets/vault_widgets/vault_empty_states.dart';
import 'package:passwordmanager/presentation/widgets/vault_widgets/vault_lock_screen.dart';
import 'package:passwordmanager/presentation/widgets/vault_widgets/vault_search_bar.dart';
import '../../../core/theme/app_theme.dart';
import '../widgets/auth/auth_background.dart';

class VaultPage extends StatefulWidget {
  const VaultPage({super.key});

  @override
  State<VaultPage> createState() => _VaultPageState();
}

class _VaultPageState extends State<VaultPage> with TickerProviderStateMixin {
  late final VaultController _ctrl;
  final _localAuth = LocalAuthentication();

  /// In-session cache: docId → decrypted plaintext password.
  /// Cleared automatically when the vault is locked.
  final Map<String, String> _decryptedCache = {};

  /// Prevents concurrent decrypt requests on the same entry.
  final Set<String> _decryptingIds = {};

  @override
  void initState() {
    super.initState();
    _ctrl = VaultController(vsync: this);
    _ctrl.addListener(() {
      if (!_ctrl.isAuthenticated) {
        // Clear cache when vault is locked
        setState(() => _decryptedCache.clear());
      } else {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
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

  // ── Enrollment dialog ──────────────────────────────────────────────────────

  void _showEnrollmentDialog() {
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
              'No biometrics or screen lock found on this device.',
              style: TextStyle(
                  color: t.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 10),
            Text(
              'To protect your passwords, please set up fingerprint, face unlock, or a PIN in your device security settings.',
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
                try {
                  await _ctrl.openSecuritySettings();
                } catch (_) {
                  _showSnackBar(
                      'Please go to Settings → Security to set up biometrics');
                }
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

  // ── Delete confirmation ────────────────────────────────────────────────────

  Future<void> _confirmDelete(String docId, String uid, String siteName) async {
    final t = context.appTheme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: t.surfaceHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFEF5350).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.delete_outline_rounded,
                  color: Color(0xFFEF5350), size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text('Delete Password',
                  style: TextStyle(
                      color: t.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w700)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to delete the saved password for:',
                style: TextStyle(
                    color: t.textSecondary, fontSize: 13, height: 1.5)),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                  color: t.surfaceMedium,
                  borderRadius: BorderRadius.circular(10)),
              child: Text(siteName,
                  style: TextStyle(
                      color: t.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700)),
            ),
            const SizedBox(height: 10),
            Text('This action cannot be undone.',
                style: TextStyle(
                    color: const Color(0xFFEF5350).withOpacity(0.8),
                    fontSize: 12,
                    fontWeight: FontWeight.w500)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel',
                style: TextStyle(
                    color: t.textDisabled, fontWeight: FontWeight.w600)),
          ),
          Container(
            decoration: BoxDecoration(
                color: const Color(0xFFEF5350),
                borderRadius: BorderRadius.circular(10)),
            child: TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _ctrl.deletePassword(docId: docId, uid: uid);
        setState(() => _decryptedCache.remove(docId));
        _showSnackBar('Password for "$siteName" deleted');
      } catch (e) {
        _showSnackBar('Failed to delete: $e', isError: true);
      }
    }
  }

  // ── Biometric gate for decryption ──────────────────────────────────────────

  /// Prompts biometrics specifically for revealing a password.
  /// Returns true if the user passes.
  Future<bool> _authenticateForDecrypt() async {
    try {
      return await _localAuth.authenticate(
        localizedReason: 'Verify your identity to reveal this password',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );
    } on PlatformException catch (e) {
      if (e.code == auth_error.notEnrolled) {
        _showEnrollmentDialog();
      } else if (e.code != auth_error.lockedOut &&
          e.code != auth_error.permanentlyLockedOut) {
        _showSnackBar('Authentication error: ${e.message}', isError: true);
      }
      return false;
    }
  }

  // ── Reveal password flow ───────────────────────────────────────────────────

  Future<void> _revealPassword({
    required String docId,
    required String encryptedPassword,
    required String siteName,
  }) async {
    // Already decrypted this session — show directly, no re-auth needed
    if (_decryptedCache.containsKey(docId)) {
      _showDecryptedBottomSheet(
        siteName: siteName,
        plainPassword: _decryptedCache[docId]!,
      );
      return;
    }

    // Prevent concurrent requests on the same entry
    if (_decryptingIds.contains(docId)) return;
    if (mounted) setState(() => _decryptingIds.add(docId));

    try {
      // ── Step 1: biometric gate ───────────────────────────────────────────
      final authed = await _authenticateForDecrypt();
      if (!authed) return;

      // ── Step 2: decrypt with device-bound AES key ────────────────────────
      final plain = await EncryptionService.decrypt(encryptedPassword);

      // ── Step 3: cache + show ─────────────────────────────────────────────
      if (mounted) {
        setState(() => _decryptedCache[docId] = plain);
        _showDecryptedBottomSheet(siteName: siteName, plainPassword: plain);
      }
    } on FormatException {
      _showSnackBar(
        'Cannot decrypt — this password may have been saved on a different device.',
        isError: true,
      );
    } catch (e) {
      _showSnackBar('Decryption error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _decryptingIds.remove(docId));
    }
  }

  void _showDecryptedBottomSheet({
    required String siteName,
    required String plainPassword,
  }) {
    final t = context.appTheme;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
        decoration: BoxDecoration(
          color: t.surfaceHigh,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: t.borderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [Color(0xFF1565C0), Color(0xFF6A1B9A)]),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.lock_open_rounded,
                      color: Colors.white, size: 16),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    siteName,
                    style: TextStyle(
                        color: t.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF1565C0).withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
                border:
                    Border.all(color: const Color(0xFF1565C0).withOpacity(0.2)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.verified_user_rounded,
                      size: 13, color: Color(0xFF1565C0)),
                  SizedBox(width: 6),
                  Text(
                    'Biometric verified · AES-256 decrypted',
                    style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF1565C0),
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Decrypted Password',
              style: TextStyle(
                  color: t.textHint, fontSize: 12, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: t.surfaceMedium,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: t.borderColor, width: 1),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      plainPassword,
                      style: TextStyle(
                        color: t.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.0,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: plainPassword));
                      Navigator.pop(context);
                      _showSnackBar('Password copied to clipboard');
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [Color(0xFF1565C0), Color(0xFF6A1B9A)]),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.copy_rounded,
                          color: Colors.white, size: 16),
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

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: context.appTheme.background,
      body: Stack(
        children: [
          AuthBackground(shieldRotate: _ctrl.shieldRotate, isDark: isDark),
          SafeArea(
            child: _ctrl.isAuthenticated
                ? _buildVaultContent()
                : VaultLockScreen(
                    controller: _ctrl,
                    onAuthenticated: () {},
                    onShowEnrollmentDialog: _showEnrollmentDialog,
                    onShowSnackBar: _showSnackBar,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildVaultContent() {
    return FadeTransition(
      opacity: _ctrl.fadeIn,
      child: SlideTransition(
        position: _ctrl.slideUp,
        child: Column(
          children: [
            VaultAppBar(controller: _ctrl, onLock: _ctrl.lockVault),
            VaultSearchBar(controller: _ctrl),
            Expanded(child: _buildPasswordList()),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordList() {
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
          return const Center(
            child: SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation(Color(0xFF1565C0)),
              ),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const VaultEmptyState();
        }

        final docs = snapshot.data!.docs.where((doc) {
          if (_ctrl.searchQuery.isEmpty) return true;
          final data = doc.data() as Map<String, dynamic>;
          final site = (data['siteName'] ?? '').toString().toLowerCase();
          final uname = (data['user_name'] ?? '').toString().toLowerCase();
          return site.contains(_ctrl.searchQuery) ||
              uname.contains(_ctrl.searchQuery);
        }).toList();

        if (docs.isEmpty) {
          return VaultNoResultsState(query: _ctrl.searchQuery);
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
          itemCount: docs.length,
          itemBuilder: (_, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            final docId = docs[i].id;
            final encryptedPassword =
                (data['encrypted_password'] ?? '') as String;

            return PasswordTile(
              siteName: data['siteName'] ?? '',
              username: data['user_name'] ?? '',
              password: _decryptedCache[docId] ?? '••••••••',
              docId: docId,
              uid: user.uid,
              onDelete: _confirmDelete,
              onRevealPassword: encryptedPassword.isNotEmpty
                  ? () => _revealPassword(
                        docId: docId,
                        encryptedPassword: encryptedPassword,
                        siteName: data['siteName'] ?? '',
                      )
                  : null,
              isDecrypting: _decryptingIds.contains(docId),
              onCopyToClipboard: (text, label) {
                Clipboard.setData(ClipboardData(text: text));
                _showSnackBar('$label copied to clipboard');
              },
            );
          },
        );
      },
    );
  }
}
