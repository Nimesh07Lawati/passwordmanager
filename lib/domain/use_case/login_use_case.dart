import 'package:passwordmanager/domain/entities/user_entity.dart';
import 'package:passwordmanager/domain/repository/authentication_repo.dart';

class Login {
  final AuthenticationRepository repository;

  Login(this.repository);

  Future<void> call(String email, String password) {
    return repository.signIn(email, password);
  }
}
