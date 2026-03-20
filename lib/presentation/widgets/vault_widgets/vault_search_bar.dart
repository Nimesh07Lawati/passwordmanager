import 'package:flutter/material.dart';
import 'package:passwordmanager/core/theme/app_theme.dart';
import 'package:passwordmanager/presentation/screens/controllers/vault_controller.dart';

class VaultSearchBar extends StatelessWidget {
  const VaultSearchBar({
    super.key,
    required this.controller,
  });

  final VaultController controller;

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: t.surfaceHigh,
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(
          children: [
            Icon(Icons.search_rounded, color: t.textHint, size: 20),
            const SizedBox(width: 5),
            Expanded(
              child: TextField(
                controller: controller.searchController,
                onChanged: controller.updateSearch,
                style: TextStyle(
                  color: t.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: 'Search passwords...',
                  hintStyle: TextStyle(color: t.textHint, fontSize: 14),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            if (controller.searchQuery.isNotEmpty)
              GestureDetector(
                onTap: () {
                  controller.searchController.clear();
                  controller.updateSearch('');
                },
                child: Icon(Icons.close_rounded, color: t.textHint, size: 18),
              ),
          ],
        ),
      ),
    );
  }
}
