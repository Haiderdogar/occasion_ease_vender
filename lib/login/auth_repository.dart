import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:occasionease/home/home_screen.dart';
import 'package:occasionease/service_selection/services_selction.dart';
import 'package:occasionease/admin_files/adminscreen.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
    required BuildContext context,
  }) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (email.toLowerCase() == 'admin@gmail.com') {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const AdminHomeScreen()),
          (route) => false,
        );
        return;
      }

      final vendorDoc = await _firestore
          .collection('newVendors')
          .doc(userCredential.user!.uid)
          .get();

      if (vendorDoc.exists) {
        final isVerified = vendorDoc.data()?['isVerified'] ?? false;
        final isBlocked = vendorDoc.data()?['isBlocked'] ?? false;

        if (!isVerified) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Your account verification is in process. We will inform you through email.'),
            ),
          );
          await _auth.signOut();
          return;
        }

        if (isBlocked) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Your account is temporarily blocked. Please contact admin@gmail.com for assistance.'),
            ),
          );
          await _auth.signOut();
          return;
        }

        await _checkSelectedServicesAndNavigate(
            context, userCredential.user!.uid);
      } else {
        throw FirebaseAuthException(
          code: 'not-a-vendor',
          message: 'No vendor registered for this email.',
        );
      }
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<void> _checkSelectedServicesAndNavigate(
      BuildContext context, String userId) async {
    final vendorDoc =
        await _firestore.collection('newVendors').doc(userId).get();
    final selectedServices =
        vendorDoc.data()?['selectedServices'] as List<dynamic>?;

    if (selectedServices == null || selectedServices.isEmpty) {
      _navigateToServicesSelection(context);
    } else {
      _navigateToHomeScreen(context);
    }
  }

  Future<void> registerVendor({
    required String email,
    required String password,
    required String username,
    required List<String> cnicImages,
    required BuildContext context,
  }) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      List<String> uploadedImageUrls = [];
      for (String imagePath in cnicImages) {
        final ref = _storage.ref().child(
            'cnic_images/${userCredential.user!.uid}/${DateTime.now().toIso8601String()}');
        await ref.putFile(File(imagePath));
        final url = await ref.getDownloadURL();
        uploadedImageUrls.add(url);
      }

      await _firestore
          .collection('newVendors')
          .doc(userCredential.user!.uid)
          .set({
        'username': username,
        'email': email,
        'cnicImages': uploadedImageUrls,
        'isVerified': false,
        'isBlocked': false,
        'selectedServices': [],
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Registration successful. Please wait for account verification.')),
      );

      Navigator.pop(context); // Return to login screen
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
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
      case 'email-already-in-use':
        return 'The email address is already in use by another account.';
      case 'weak-password':
        return 'The password provided is too weak.';
      default:
        return 'An error occurred. Please try again.';
    }
  }
}
