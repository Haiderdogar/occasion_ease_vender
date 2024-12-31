import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

final serviceProvider =
    StateNotifierProvider<ServiceNotifier, AsyncValue<void>>((ref) {
  return ServiceNotifier();
});

class ServiceNotifier extends StateNotifier<AsyncValue<void>> {
  ServiceNotifier() : super(const AsyncValue.data(null));

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<void> addService(
      {required String name,
      required String description,
      required double price,
      required String serviceType,
      required List<String> selectedServices,
      required List<File> images,
      required String location,
      required String serviceName}) async {
    try {
      state = const AsyncValue.loading();

      // Upload images
      List<String> imageUrls = [];
      for (var image in images) {
        String fileName = DateTime.now().millisecondsSinceEpoch.toString();
        Reference ref = _storage.ref().child('marriage_halls/$fileName');
        await ref.putFile(image);
        String downloadUrl = await ref.getDownloadURL();
        imageUrls.add(downloadUrl);
      }

      // Add to Firestore
      await _firestore.collection(serviceName).add({
        'name': name,
        'description': description,
        'price': price,
        'serviceType': serviceType,
        'selectedServices': selectedServices,
        'images': imageUrls,
        'location': location,
        'createdAt': FieldValue.serverTimestamp(),
        'venderId': FirebaseAuth.instance.currentUser!.uid
      });

      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}
