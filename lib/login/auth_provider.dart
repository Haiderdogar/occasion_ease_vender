import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:occasionease/login/auth_repository.dart';

final emailProvider = StateProvider<String>((ref) => '');
final passwordProvider = StateProvider<String>((ref) => '');
final usernameProvider = StateProvider<String>((ref) => '');
final cnicImagesProvider = StateProvider<List<String>>((ref) => []);
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
            context: context,
          );

      _ref.read(errorMessageProvider.notifier).state = null;
    } catch (e) {
      _ref.read(errorMessageProvider.notifier).state = e.toString();
    } finally {
      _ref.read(isLoadingProvider.notifier).state = false;
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    if (email.toLowerCase() == 'admin@gmail.com') {
      throw FirebaseAuthException(
        code: 'admin-email',
        message: 'Password reset is not allowed for this email.',
      );
    }

    await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
  }

  Future<void> registerVendor({required BuildContext context}) async {
    final email = _ref.read(emailProvider);
    final password = _ref.read(passwordProvider);
    final username = _ref.read(usernameProvider);
    final cnicImages = _ref.read(cnicImagesProvider);

    if (email.isEmpty ||
        password.isEmpty ||
        username.isEmpty ||
        cnicImages.length != 2) {
      _ref.read(errorMessageProvider.notifier).state =
          'Please fill in all fields and upload 2 CNIC images';
      return;
    }

    if (email.toLowerCase() == 'admin@gmail.com') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please use a different email address')),
      );
      return;
    }

    try {
      _ref.read(isLoadingProvider.notifier).state = true;
      _ref.read(errorMessageProvider.notifier).state = null;

      await _ref.read(authRepositoryProvider).registerVendor(
            email: email,
            password: password,
            username: username,
            cnicImages: cnicImages,
            context: context,
          );

      _ref.read(errorMessageProvider.notifier).state = null;
    } catch (e) {
      _ref.read(errorMessageProvider.notifier).state = e.toString();
    } finally {
      _ref.read(isLoadingProvider.notifier).state = false;
    }
  }
}
