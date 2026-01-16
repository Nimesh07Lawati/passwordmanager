import 'package:passwordmanager/domain/repository/authentication_repo.dart';

class AuthRepoImpl extends AuthenticationRepository {
  @override
  Future<void> signIn(String email, String password) async {
    // Implement sign-in logic here
  }

  @override
  Future<void> signUp(String email, String password) async {
    // Implement sign-up logic here
  }

  @override
  Future<void> signOut() async {
    // Implement sign-out logic here
  }
}
