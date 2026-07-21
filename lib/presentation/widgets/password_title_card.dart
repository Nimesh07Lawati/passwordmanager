import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

// Shared sentinel so vault_page and password_tile always match
const String kMaskedPassword = '••••••••';

class PasswordTile extends StatelessWidget {
  const PasswordTile({
    super.key,
    required this.siteName,
    required this.username,
    required this.password,
    required this.docId,
    required this.uid,
    required this.onDelete,
    required this.onCopyToClipboard,
    this.onRevealPassword,
    required this.isDecrypting,
  });

  final String siteName;
  final String username;
  final String password;
  final String docId;
  final String uid;
  final Future<void> Function(String docId, String uid, String siteName)
      onDelete;
  final void Function(String text, String label) onCopyToClipboard;
  final Future<void> Function()? onRevealPassword;
  final bool isDecrypting;

  static const _colorPairs = [
    [Color(0xFF1565C0), Color(0xFF6A1B9A)],
    [Color(0xFF00838F), Color(0xFF1565C0)],
    [Color(0xFF6A1B9A), Color(0xFFAD1457)],
    [Color(0xFF2E7D32), Color(0xFF00838F)],
    [Color(0xFFE65100), Color(0xFF6A1B9A)],
  ];

  List<Color> get _colorPair {
    final initial = siteName.isNotEmpty ? siteName[0].toUpperCase() : '?';
    return _colorPairs[initial.codeUnitAt(0) % _colorPairs.length];
  }

  String get _initial => siteName.isNotEmpty ? siteName[0].toUpperCase() : '?';

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: t.surfaceHigh,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: t.borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
                colors: _colorPair,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                _initial,
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
            Divider(color: t.borderColor, thickness: 1, height: 1),
            const SizedBox(height: 14),
            _DetailRow(
              t: t,
              label: 'Username',
              value: username,
              icon: Icons.alternate_email_rounded,
              onCopy: () => onCopyToClipboard(username, 'Username'),
            ),
            const SizedBox(height: 10),
            _PasswordRow(
              t: t,
              password: password,
              isDecrypted: password != kMaskedPassword,
              isDecrypting: isDecrypting,
              onRevealPassword: onRevealPassword,
              onCopy: () => onCopyToClipboard(password, 'Password'),
            ),
            const SizedBox(height: 10),
            _DeleteButton(
              onTap: () => onDelete(docId, uid, siteName),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Detail row (username) ─────────────────────────────────────────────────────

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.t,
    required this.label,
    required this.value,
    required this.icon,
    required this.onCopy,
  });

  final AppThemeExtension t;
  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
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
                  label.toUpperCase(),
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
                color: const Color(0xFF1565C0).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.copy_rounded,
                  size: 14, color: Color(0xFF1565C0)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Password row with show/hide toggle ───────────────────────────────────────

class _PasswordRow extends StatefulWidget {
  const _PasswordRow({
    required this.t,
    required this.password,
    required this.isDecrypted,
    required this.isDecrypting,
    required this.onRevealPassword,
    required this.onCopy,
  });

  final AppThemeExtension t;
  final String password;
  final bool isDecrypted;
  final bool isDecrypting;
  final Future<void> Function()? onRevealPassword;
  final VoidCallback onCopy;

  @override
  State<_PasswordRow> createState() => _PasswordRowState();
}

class _PasswordRowState extends State<_PasswordRow> {
  bool _visible = false;

  @override
  void didUpdateWidget(_PasswordRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the vault was locked and password reverted to dots, hide again
    if (!widget.isDecrypted) {
      _visible = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final showText = widget.isDecrypted && _visible;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: widget.t.surfaceMedium,
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
                    color: widget.t.textDisabled,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  showText ? widget.password : '••••••••••••',
                  style: TextStyle(
                    fontSize: 13,
                    color: widget.t.textPrimary,
                    fontWeight: FontWeight.w500,
                    letterSpacing: showText ? 0 : 2,
                  ),
                ),
              ],
            ),
          ),
          // ── Eye / spinner button ──────────────────────────────────────
          GestureDetector(
            onTap: widget.isDecrypting
                ? null
                : () {
                    if (!widget.isDecrypted) {
                      // Trigger biometric prompt + decryption in parent
                      widget.onRevealPassword?.call();
                    } else {
                      // Already decrypted — just toggle visibility locally
                      setState(() => _visible = !_visible);
                    }
                  },
            child: Container(
              padding: const EdgeInsets.all(6),
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF6A1B9A).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: widget.isDecrypting
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        valueColor: AlwaysStoppedAnimation(Color(0xFF6A1B9A)),
                      ),
                    )
                  : Icon(
                      showText
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                      size: 14,
                      color: const Color(0xFF6A1B9A),
                    ),
            ),
          ),
          // ── Copy button ───────────────────────────────────────────────
          GestureDetector(
            onTap: widget.onCopy,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF1565C0).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.copy_rounded,
                  size: 14, color: Color(0xFF1565C0)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Delete button ─────────────────────────────────────────────────────────────

class _DeleteButton extends StatelessWidget {
  const _DeleteButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFEF5350).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFEF5350).withValues(alpha: 0.25),
            width: 1,
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete_outline_rounded,
                size: 16, color: Color(0xFFEF5350)),
            SizedBox(width: 8),
            Text(
              'Delete Password',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFFEF5350),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
