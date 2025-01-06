import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:occasionease/admin_files/adminscreen.dart';
import 'package:occasionease/home/home_screen.dart';
import 'package:occasionease/login/auth_repository.dart';
import 'package:occasionease/service_selection/services_selction.dart';

final emailProvider = StateProvider<String>((ref) => '');
final passwordProvider = StateProvider<String>((ref) => '');
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

      if (email == 'admin@gmail.com') {
        // Navigate to Admin Home if Admin
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const AdminHomeScreen()),
          (route) => false,
        );
        return;
      }

      // Check vendor login status
      await checkLoginStatus(context);

      _ref.read(errorMessageProvider.notifier).state = null;
    } catch (e) {
      _ref.read(errorMessageProvider.notifier).state = e.toString();
    } finally {
      _ref.read(isLoadingProvider.notifier).state = false;
    }
  }

  Future<void> checkLoginStatus(BuildContext context) async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    try {
      final String userId = FirebaseAuth.instance.currentUser!.uid;
      final DocumentReference userDoc =
          firestore.collection('vendors').doc(userId);
      final DocumentSnapshot snapshot = await userDoc.get();

      if (!snapshot.exists) {
        await userDoc.set({
          'loginsuccess': false,
        });
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const ServicesSelection()),
          (route) => false,
        );
      } else {
        final data = snapshot.data() as Map<String, dynamic>;
        final bool loginSuccess = data['loginsuccess'] ?? false;

        if (loginSuccess) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
            (route) => false,
          );
        } else {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const ServicesSelection()),
            (route) => false,
          );
        }
      }
    } catch (e) {
      throw Exception('Failed to check login status: $e');
    }
  }
}
