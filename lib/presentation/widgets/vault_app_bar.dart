import 'package:flutter/material.dart';
import 'package:passwordmanager/presentation/screens/controllers/vault_controller.dart';
import '../../../core/theme/app_theme.dart';

class VaultAppBar extends StatelessWidget {
  const VaultAppBar({
    super.key,
    required this.controller,
    required this.onLock,
  });

  final VaultController controller;
  final VoidCallback onLock;

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;

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
          GestureDetector(
            onTap: onLock,
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
}
