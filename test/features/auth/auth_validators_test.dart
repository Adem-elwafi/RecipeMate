import 'package:flutter_test/flutter_test.dart';
import 'package:recipemate/features/auth/utils/auth_validators.dart';

void main() {
  group('AuthValidators', () {
    test('email vide ou invalide', () {
      expect(AuthValidators.email(''), isNotNull);
      expect(AuthValidators.email('pas-un-email'), isNotNull);
      expect(AuthValidators.email('farah@recipemate.app'), isNull);
    });

    test('mot de passe trop court', () {
      expect(AuthValidators.password('12345'), isNotNull);
      expect(AuthValidators.password('123456'), isNull);
    });

    test('confirmation identique', () {
      expect(AuthValidators.confirmation('123456', '123456'), isNull);
      expect(AuthValidators.confirmation('autre', '123456'), isNotNull);
    });

    test('champ obligatoire', () {
      expect(AuthValidators.required('  ', 'Le nom'), isNotNull);
      expect(AuthValidators.required('Farah', 'Le nom'), isNull);
    });
  });
}
