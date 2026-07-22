import 'package:flutter/material.dart';

class GradientButton extends StatelessWidget {
  final VoidCallback? onTap;
  final bool isLoading;
  final String label;

  const GradientButton({
    super.key,
    required this.onTap,
    required this.isLoading,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          gradient: onTap == null
              ? const LinearGradient(
                  colors: [Color(0xFF9E9E9E), Color(0xFF757575)],
                )
              : const LinearGradient(
                  colors: [Color(0xFF1565C0), Color(0xFF6A1B9A)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: onTap == null
              ? []
              : [
                  BoxShadow(
                    color: const Color(0xFF1565C0).withValues(alpha: 0.45),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
        ),
      ),
    );
  }
}
