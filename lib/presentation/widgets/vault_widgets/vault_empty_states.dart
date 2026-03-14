import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class VaultEmptyState extends StatelessWidget {
  const VaultEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;

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
}

class VaultNoResultsState extends StatelessWidget {
  const VaultNoResultsState({super.key, required this.query});
  final String query;

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 40, color: t.textDisabled),
          const SizedBox(height: 14),
          Text(
            'No results for "$query"',
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
