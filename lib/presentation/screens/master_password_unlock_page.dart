import 'package:passwordmanager/core/extension/import_extensios.dart';
import 'package:passwordmanager/presentation/screens/controllers/vault_controller.dart';

/// Shown when the vault has EXISTING data (kdfSalt/keyVerifier already
/// in Firestore) but no key is cached locally — i.e. after a reinstall,
/// a new device, or cleared app storage. The user re-enters their
/// master password to re-derive the same AES key and unlock everything
/// again.
class MasterPasswordUnlockScreen extends StatefulWidget {
  const MasterPasswordUnlockScreen({
    super.key,
    required this.controller,
    required this.onShowSnackBar,
  });

  final VaultController controller;
  final void Function(String message, {bool isError}) onShowSnackBar;

  @override
  State<MasterPasswordUnlockScreen> createState() =>
      _MasterPasswordUnlockScreenState();
}

class _MasterPasswordUnlockScreenState
    extends State<MasterPasswordUnlockScreen> {
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;
  bool _submitting = false;
  String? _errorText;

  @override
  void dispose() {
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_passwordCtrl.text.isEmpty || _submitting) return;

    setState(() {
      _submitting = true;
      _errorText = null;
    });

    try {
      final ok =
          await widget.controller.unlockWithMasterPassword(_passwordCtrl.text);
      if (!ok) {
        setState(() => _errorText = 'Incorrect master password');
      } else {
        widget.onShowSnackBar('Vault unlocked');
      }
    } catch (e) {
      setState(() => _errorText = 'Something went wrong: $e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _confirmReset() async {
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
                color: const Color(0xFFEF5350).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.warning_amber_rounded,
                  color: Color(0xFFEF5350), size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Reset Vault?',
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
              'Without your master password, every saved password is '
              'permanently unreadable — this is by design and can\'t be '
              'undone.',
              style:
                  TextStyle(color: t.textSecondary, fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 10),
            Text(
              'Resetting will permanently delete all saved passwords and '
              'let you start fresh with a new master password.',
              style: TextStyle(
                  color: const Color(0xFFEF5350).withValues(alpha: 0.9),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  height: 1.4),
            ),
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
              child: const Text('Delete Everything',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await widget.controller.resetVaultAndForgetMasterPassword();
        widget.onShowSnackBar('Vault reset — set up a new master password');
      } catch (e) {
        widget.onShowSnackBar('Reset failed: $e', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1565C0), Color(0xFF6A1B9A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(Icons.lock_reset_rounded,
                  color: Colors.white, size: 30),
            ),
            const SizedBox(height: 20),
            Text(
              'Enter Your Master Password',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: t.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'We couldn\'t find your saved encryption key on this device '
              '— this happens after a reinstall or on a new device. Enter '
              'your master password to unlock your existing vault.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: t.textSecondary,
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),
            Container(
              decoration: BoxDecoration(
                color: t.surfaceMedium,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _errorText != null
                      ? const Color(0xFFEF5350).withValues(alpha: 0.5)
                      : t.borderColor,
                  width: 1,
                ),
              ),
              child: TextField(
                controller: _passwordCtrl,
                obscureText: _obscure,
                onChanged: (_) => setState(() => _errorText = null),
                onSubmitted: (_) => _submit(),
                style: TextStyle(color: t.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'Master Password',
                  labelStyle: TextStyle(color: t.textHint, fontSize: 13),
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  suffixIcon: IconButton(
                    onPressed: () => setState(() => _obscure = !_obscure),
                    icon: Icon(
                      _obscure
                          ? Icons.visibility_rounded
                          : Icons.visibility_off_rounded,
                      size: 18,
                      color: t.textHint,
                    ),
                  ),
                ),
              ),
            ),
            if (_errorText != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.error_outline_rounded,
                      size: 15, color: Color(0xFFEF5350)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _errorText!,
                      style: const TextStyle(
                        color: Color(0xFFEF5350),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFF1565C0), Color(0xFF6A1B9A)]),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: TextButton(
                  onPressed: _submitting ? null : _submit,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _submitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : const Text(
                          'Unlock Vault',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            TextButton(
              onPressed: _confirmReset,
              child: Text(
                'Forgot your master password?',
                style: TextStyle(
                  color: t.textDisabled,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
