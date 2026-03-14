import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:passwordmanager/presentation/screens/controllers/vault_controller.dart';
import 'package:passwordmanager/presentation/widgets/vault_widgets/password_title_card.dart';
import 'package:passwordmanager/presentation/widgets/vault_widgets/vault_app_bar.dart';
import 'package:passwordmanager/presentation/widgets/vault_widgets/vault_empty_states.dart';
import 'package:passwordmanager/presentation/widgets/vault_widgets/vault_lock_screen.dart';
import '../../../core/theme/app_theme.dart';
import '../widgets/auth/auth_background.dart';

class VaultPage extends StatefulWidget {
  const VaultPage({super.key});

  @override
  State<VaultPage> createState() => _VaultPageState();
}

class _VaultPageState extends State<VaultPage> with TickerProviderStateMixin {
  late final VaultController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = VaultController(vsync: this);
    _ctrl.addListener(() => setState(() {}));
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
            onPressed: () => Navigator.pop(context),
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
                Navigator.pop(context);
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

  // ── Delete confirmation dialog ─────────────────────────────────────────────
  Future<void> _confirmDelete(String docId, String uid, String siteName) async {
    final t = context.appTheme;
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
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
              child: Text(
                'Delete Password',
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
              'Are you sure you want to delete the saved password for:',
              style:
                  TextStyle(color: t.textSecondary, fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: t.surfaceMedium,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                siteName,
                style: TextStyle(
                    color: t.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'This action cannot be undone.',
              style: TextStyle(
                  color: const Color(0xFFEF5350).withOpacity(0.8),
                  fontSize: 12,
                  fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel',
                style: TextStyle(
                    color: t.textDisabled, fontWeight: FontWeight.w600)),
          ),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFEF5350),
              borderRadius: BorderRadius.circular(10),
            ),
            child: TextButton(
              onPressed: () => Navigator.pop(context, true),
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
        _showSnackBar('Password for "$siteName" deleted');
      } catch (e) {
        _showSnackBar('Failed to delete: $e', isError: true);
      }
    }
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

  // ── Vault content (app bar + search + list) ────────────────────────────────
  Widget _buildVaultContent() {
    return FadeTransition(
      opacity: _ctrl.fadeIn,
      child: SlideTransition(
        position: _ctrl.slideUp,
        child: Column(
          children: [
            VaultAppBar(
              controller: _ctrl,
              onLock: _ctrl.lockVault,
            ),
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
            return PasswordTile(
              siteName: data['siteName'] ?? '',
              username: data['user_name'] ?? '',
              password: data['password'] ?? '',
              docId: docs[i].id,
              uid: user.uid,
              onDelete: _confirmDelete,
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
