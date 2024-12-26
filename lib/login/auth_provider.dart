import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:occasionease/home/home_screen.dart';
import 'package:occasionease/login/auth_repository.dart';

final emailProvider = StateProvider<String>((ref) => '');
final passwordProvider = StateProvider<String>((ref) => '');
final rememberMeProvider = StateProvider<bool>((ref) => false);
final isLoadingProvider = StateProvider<bool>((ref) => false);
final errorMessageProvider = StateProvider<String?>((ref) => null);

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

final authControllerProvider = Provider((ref) {
  return AuthController(ref);
});

class AuthController {
  final Ref _ref;
  AuthController(this._ref);
  Future<void> signInWithEmailAndPassword(
      {required BuildContext context}) async {
    final email = _ref.read(emailProvider);
    final password = _ref.read(passwordProvider);

    if (email.isEmpty || password.isEmpty) {
      _ref.read(errorMessageProvider.notifier).state =
          'Please fill in all fields';
      return;
    }

    try {
      _ref.read(isLoadingProvider.notifier).state = true;
      _ref.read(errorMessageProvider.notifier).state = null;

      await _ref.read(authRepositoryProvider).signInWithEmailAndPassword(
            email: email,
            password: password,
          );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
        (route) => false, // This ensures all previous routes are removed
      );
      _ref.read(errorMessageProvider.notifier).state = null;
    } catch (e) {
      _ref.read(errorMessageProvider.notifier).state = e.toString();
    } finally {
      _ref.read(isLoadingProvider.notifier).state = false;
    }
  }
}
