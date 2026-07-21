import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class PasswordInfoRow extends StatelessWidget {
  final AppThemeExtension theme;

  const PasswordInfoRow({
    super.key,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 14,
            color: theme.textHint.withOpacity(0.7),
          ),
          const SizedBox(width: 6),
          Text(
            'Password must be at least 6 characters',
            style: TextStyle(
              fontSize: 11,
              color: theme.textHint.withOpacity(0.7),
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
