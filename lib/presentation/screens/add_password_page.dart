import 'package:flutter/material.dart';

class AddPasswordPage extends StatelessWidget {
  const AddPasswordPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Password")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: const [
            TextField(
              decoration: InputDecoration(labelText: "App / Website"),
            ),
            SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(labelText: "Username"),
            ),
            SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(labelText: "Password"),
              obscureText: true,
            ),
            SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: null,
                child: Text("Save"),
              ),
            )
          ],
        ),
      ),
    );
  }
}
