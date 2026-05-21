// ── Validation ─────────────────────────────────────────────────────────────
String? validateEmail(String? value) {
  if (value == null || value.isEmpty) return 'Please enter your email';
  if (!value.contains('@')) return 'Please enter a valid email';
  return null;
}

String? validatePassword(String? value) {
  if (value == null || value.isEmpty) return 'Please enter your password';
  if (value.length < 6) return 'Password must be at least 6 characters';
  return null;
}

String? validateConfirmPassword(String? value, dynamic passwordController) {
  if (value == null || value.isEmpty) return 'Please confirm your password';
  if (value != passwordController.text) return 'Passwords do not match';
  return null;
}
