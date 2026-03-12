import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<void> savePassword({
  required String siteName,
  required String username,
  required String password,
  required String encryptedPassword,
}) async {
  final user = FirebaseAuth.instance.currentUser;

  if (user == null) return;

  await FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('passwords')
      .add({
    'siteName': siteName,
    'user_name': username,
    'password': password,
    'encrypted_password': encryptedPassword,
    'createdAt': FieldValue.serverTimestamp(),
  });
}
