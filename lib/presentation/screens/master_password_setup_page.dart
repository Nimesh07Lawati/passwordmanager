import 'package:passwordmanager/core/extension/import_extensios.dart';
import 'package:passwordmanager/presentation/screens/controllers/vault_controller.dart';

/// Shown the FIRST time a user reaches the vault with no master password
/// set up yet (fresh account). They choose a master password here; it's
/// used to derive the AES key that encrypts every saved password.
///
/// This is the one secret that makes reinstall-recovery possible — make
/// sure the copy makes clear it can't be reset without losing all data.
class MasterPasswordSetupScreen extends StatefulWidget {
  const MasterPasswordSetupScreen({
    super.key,
    required this.controller,
    required this.onShowSnackBar,
  });

  final VaultController controller;
  final void Function(String message, {bool isError}) onShowSnackBar;

  @override
  State<MasterPasswordSetupScreen> createState() =>
      _MasterPasswordSetupScreenState();
}

class _MasterPasswordSetupScreenState extends State<MasterPasswordSetupScreen> {
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _submitting = false;
  String? _errorText;

  static const _minLength = 8;

  @override
  void dispose() {
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  // ── Strength scoring (simple heuristic, 0-4) ────────────────────────────
  int get _strength {
    final p = _passwordCtrl.text;
    var score = 0;
    if (p.length >= _minLength) score++;
    if (p.length >= 12) score++;
    if (RegExp(r'[A-Z]').hasMatch(p) && RegExp(r'[a-z]').hasMatch(p)) score++;
    if (RegExp(r'[0-9]').hasMatch(p) || RegExp(r'[^\w\s]').hasMatch(p)) {
      score++;
    }
    return score.clamp(0, 4);
  }

  String get _strengthLabel {
    switch (_strength) {
      case 0:
      case 1:
        return 'Weak';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      default:
        return 'Strong';
    }
  }

  Color get _strengthColor {
    switch (_strength) {
      case 0:
      case 1:
        return const Color(0xFFEF5350);
      case 2:
        return const Color(0xFFFFA726);
      case 3:
        return const Color(0xFF66BB6A);
      default:
        return const Color(0xFF2E7D32);
    }
  }

  bool get _canSubmit =>
      _passwordCtrl.text.length >= _minLength &&
      _passwordCtrl.text == _confirmCtrl.text &&
      !_submitting;

  Future<void> _submit() async {
    if (_passwordCtrl.text.length < _minLength) {
      setState(() => _errorText =
          'Master password must be at least $_minLength characters');
      return;
    }
    if (_passwordCtrl.text != _confirmCtrl.text) {
      setState(() => _errorText = 'Passwords don\'t match');
      return;
    }

    setState(() {
      _submitting = true;
      _errorText = null;
    });

    try {
      await widget.controller.createMasterPassword(_passwordCtrl.text);
      widget.onShowSnackBar('Master password set — your vault is protected');
    } catch (e) {
      setState(() => _errorText = 'Something went wrong: $e');
    } finally {
      if (mounted) setState(() => _submitting = false);
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
              child: const Icon(Icons.vpn_key_rounded,
                  color: Colors.white, size: 30),
            ),
            const SizedBox(height: 20),
            Text(
              'Create a Master Password',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: t.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'This protects your vault and is the only way to recover '
              'your passwords after reinstalling the app or switching '
              'devices. Choose something memorable — it can\'t be reset '
              'without losing your saved passwords.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: t.textSecondary,
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),

            // ── Password field ────────────────────────────────────────
            _PasswordField(
              t: t,
              controller: _passwordCtrl,
              label: 'Master Password',
              obscure: _obscurePassword,
              onToggleObscure: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
              onChanged: (_) => setState(() => _errorText = null),
            ),

            if (_passwordCtrl.text.isNotEmpty) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _strength / 4,
                        minHeight: 5,
                        backgroundColor: t.surfaceMedium,
                        valueColor: AlwaysStoppedAnimation(_strengthColor),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _strengthLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _strengthColor,
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 14),

            // ── Confirm field ─────────────────────────────────────────
            _PasswordField(
              t: t,
              controller: _confirmCtrl,
              label: 'Confirm Master Password',
              obscure: _obscureConfirm,
              onToggleObscure: () =>
                  setState(() => _obscureConfirm = !_obscureConfirm),
              onChanged: (_) => setState(() => _errorText = null),
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
                  gradient: _canSubmit
                      ? const LinearGradient(
                          colors: [Color(0xFF1565C0), Color(0xFF6A1B9A)])
                      : null,
                  color: _canSubmit ? null : t.surfaceMedium,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: TextButton(
                  onPressed: _canSubmit ? _submit : null,
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
                      : Text(
                          'Secure My Vault',
                          style: TextStyle(
                            color: _canSubmit ? Colors.white : t.textDisabled,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shared password input styling ─────────────────────────────────────────

class _PasswordField extends StatelessWidget {
  const _PasswordField({
    required this.t,
    required this.controller,
    required this.label,
    required this.obscure,
    required this.onToggleObscure,
    required this.onChanged,
  });

  final AppThemeExtension t;
  final TextEditingController controller;
  final String label;
  final bool obscure;
  final VoidCallback onToggleObscure;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: t.surfaceMedium,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: t.borderColor, width: 1),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        onChanged: onChanged,
        style: TextStyle(color: t.textPrimary, fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: t.textHint, fontSize: 13),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          suffixIcon: IconButton(
            onPressed: onToggleObscure,
            icon: Icon(
              obscure ? Icons.visibility_rounded : Icons.visibility_off_rounded,
              size: 18,
              color: t.textHint,
            ),
          ),
        ),
      ),
    );
  }
}
