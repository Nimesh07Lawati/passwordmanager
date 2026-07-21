import 'package:flutter/material.dart';

class PasswordCard extends StatelessWidget {
  final String title;
  final String username;
  final String? category;
  final int? strength;
  final String? lastUsed;
  final IconData? iconData;
  final Color? iconColor;
  final VoidCallback? onTap;
  final VoidCallback? onCopy;
  final VoidCallback? onVisibilityTap;

  const PasswordCard({
    super.key,
    required this.title,
    required this.username,
    this.category,
    this.strength,
    this.lastUsed,
    this.iconData,
    this.iconColor,
    this.onTap,
    this.onCopy,
    this.onVisibilityTap,
  });

  // Simple constructor for backward compatibility
  const PasswordCard.simple({
    super.key,
    required this.title,
    required this.username,
    this.category,
    this.strength,
    this.lastUsed,
    this.iconData,
    this.iconColor,
    this.onTap,
    this.onCopy,
    this.onVisibilityTap,
  });

  Color _getStrengthColor() {
    if (strength == null) return Colors.grey;
    if (strength! >= 80) return Colors.green;
    if (strength! >= 60) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Icon with colored background
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: (iconColor ?? Colors.blue).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  iconData ?? Icons.lock_outline,
                  color: iconColor ?? Colors.blue.shade700,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title and Category
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (category != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              category!,
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Username and Copy button
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            username,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (onCopy != null)
                          GestureDetector(
                            onTap: onCopy,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              child: Icon(
                                Icons.copy,
                                size: 16,
                                color: Colors.grey.shade400,
                              ),
                            ),
                          ),
                      ],
                    ),

                    // Strength indicator and Last used
                    if (strength != null || lastUsed != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          if (strength != null) ...[
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: strength! / 100,
                                  backgroundColor: Colors.grey.shade200,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    _getStrengthColor(),
                                  ),
                                  minHeight: 4,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '$strength%',
                              style: TextStyle(
                                fontSize: 12,
                                color: _getStrengthColor(),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                          if (lastUsed != null && strength == null) ...[
                            Text(
                              lastUsed!,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade400,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],

                    // Last used (if not shown with strength)
                    if (lastUsed != null && strength != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Last used: $lastUsed',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Visibility icon
              if (onVisibilityTap != null)
                IconButton(
                  onPressed: onVisibilityTap,
                  icon: const Icon(Icons.visibility_outlined),
                  color: Colors.grey.shade600,
                  splashRadius: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
