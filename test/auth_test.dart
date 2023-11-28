import 'package:myapp/services/auth/auth_exceptions.dart';
import 'package:myapp/services/auth/auth_provider.dart';
import 'package:myapp/services/auth/auth_user.dart';
import 'package:test/test.dart';

void main() {
  group('Mock Authentication', () {
    final provider = MockAuthProvider();
    test('should not initialize', () {
      expect(provider.initialized, false);
    });
    test('should not initialize on logout', () {
      expect(
        provider.logOut(),
        throwsA(const TypeMatcher<NotInitializedAuthException>()),
      );
    });
    test('should be initialized', () async {
      await provider.initialize();
      expect(provider.initialized, true);
    });
    test('user should be null', () {
      expect(provider.currentUser, null);
    });
    test('should initialize in less than 2 seconds', () async {
      await provider.initialize();
      expect(provider.initialized, true);
    },
        timeout: const Timeout(
          Duration(seconds: 2),
        ));
    test('create user should delegate to logIn', () async {
      final wrongEmailUser = provider.createUser(
        email: 'anyemail@gmail.com',
        password: 'bar',
      );
      expect(
          () => wrongEmailUser,
          throwsA(
            const TypeMatcher<UserNotFoundAuthException>(),
          ));
      final badPassword = provider.createUser(
        email: 'foo',
        password: 'anypassword',
      );
      expect(
          () => badPassword,
          throwsA(
            const TypeMatcher<WrongPasswordAuthException>(),
          ));
      final user = await provider.createUser(
        email: 'foo',
        password: 'bar',
      );
      expect(provider.currentUser, user);
      expect(user.isEmailVerified, false);
    });
    test('Logged in user should be able to verify', () {
      provider.sendEmailVerification();
      final user = provider.currentUser;
      expect(user, isNotNull);
      expect(user!.isEmailVerified, true);
    });
    test('user should be able to log out and log in', () async {
      await provider.logOut();
      await provider.logIn(
        email: 'email',
        password: 'password',
      );
      final user = provider.currentUser;
      expect(user, isNotNull);
    });
  });
}

class NotInitializedAuthException implements Exception {}

class MockAuthProvider implements AuthProvider {
  AuthUser? _user;
  var _initialized = false;
  bool get initialized => _initialized;

  @override
  Future<AuthUser> createUser({
    required String email,
    required String password,
  }) async {
    if (!initialized) throw NotInitializedAuthException();
    await Future.delayed(const Duration(seconds: 1));
    return logIn(
      email: email,
      password: password,
    );
  }

  @override
  AuthUser? get currentUser => _user;
  @override
  Future<void> initialize() async {
    await Future.delayed(const Duration(seconds: 1));
    _initialized = true;
  }

  @override
  Future<AuthUser> logIn({
    required String email,
    required String password,
  }) {
    if (!initialized) throw NotInitializedAuthException();
    if (email == 'anyemail@gmail.com') throw UserNotFoundAuthException();
    if (password == 'anypassword') throw WrongPasswordAuthException();
    const user = AuthUser(isEmailVerified: false);
    _user = user;
    return Future.value(user);
  }

  @override
  Future<void> logOut() async {
    if (!initialized) throw NotInitializedAuthException();
    if (_user == null) throw UserNotFoundAuthException();
    await Future.delayed(const Duration(seconds: 1));
    _user = null;
  }

  @override
  Future<void> sendEmailVerification() async {
    if (!initialized) throw NotInitializedAuthException();
    final user = _user;
    if (user == null) throw UserNotFoundAuthException();
    const newUser = AuthUser(isEmailVerified: true);
    _user = newUser;
  }
}
