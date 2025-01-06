import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:occasionease/home/home_screen.dart';
import 'package:occasionease/service_selection/services_selction.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Check for admin login
      if (email == 'admin@gmail.com') {
        return userCredential;
      }

      // Check vendor status in Firestore
      final userDoc = await _firestore
          .collection('vendors')
          .doc(userCredential.user!.uid)
          .get();
      if (!userDoc.exists || userDoc.data()?['isVendor'] != true) {
        throw FirebaseAuthException(
          code: 'not-a-vendor',
          message: 'No vendor registered for this email.',
        );
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<void> checkLoginStatus(BuildContext context) async {
    try {
      final String userId = _auth.currentUser!.uid;
      final DocumentReference userDoc =
          _firestore.collection('vendors').doc(userId);
      final DocumentSnapshot snapshot = await userDoc.get();

      if (!snapshot.exists) {
        await userDoc.set({
          'loginsuccess': false,
        });
        _navigateToServicesSelection(context);
      } else {
        final data = snapshot.data() as Map<String, dynamic>;
        final bool loginSuccess = data['loginsuccess'] ?? false;

        if (loginSuccess) {
          _navigateToHomeScreen(context);
        } else {
          _navigateToServicesSelection(context);
        }
      }
    } catch (e) {
      throw Exception('Failed to check login status: $e');
    }
  }

  void _navigateToServicesSelection(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const ServicesSelection()),
      (route) => false,
    );
  }

  void _navigateToHomeScreen(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
      (route) => false,
    );
  }

  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'invalid-email':
        return 'The email address is invalid.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'not-a-vendor':
        return e.message ?? 'No vendor registered for this email.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return 'An error occurred. Please try again.';
    }
  }
}
