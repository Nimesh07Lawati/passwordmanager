import 'package:flutter/material.dart';
import 'package:passwordmanager/presentation/widgets/password_card_widget.dart';
import 'add_password_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Passwords"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          PasswordCard(
            title: "Facebook",
            username: "john123",
          ),
          PasswordCard(
            title: "Instagram",
            username: "john_doe",
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddPasswordPage()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
