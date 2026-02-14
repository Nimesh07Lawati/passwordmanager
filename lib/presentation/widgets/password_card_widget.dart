import 'package:flutter/material.dart';

class PasswordCard extends StatelessWidget {
  final String title;
  final String username;

  const PasswordCard({
    super.key,
    required this.title,
    required this.username,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const Icon(Icons.lock_outline),
        title: Text(title),
        subtitle: Text(username),
        trailing: const Icon(Icons.visibility),
      ),
    );
  }
}
