import 'package:passwordmanager/domain/entities/user_entity.dart';
import 'package:passwordmanager/domain/repository/authentication_repo.dart';

class Register {
  final AuthenticationRepository repository;

  Register(this.repository);

  Future<void> call(String email, String password) {
    return repository.signIn(email, password);
  }
}
