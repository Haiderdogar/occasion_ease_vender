import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';

// State providers to manage image selection and input fields
final imageProvider = StateProvider<List<File>>((ref) => []);
final titleProvider = StateProvider<String>((ref) => '');
final descriptionProvider = StateProvider<String>((ref) => '');

class DataUploadScreen extends ConsumerWidget {
  const DataUploadScreen({super.key});

  // Function to pick images from gallery
  Future<void> pickImages(WidgetRef ref) async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage();

    final imageFiles = pickedFiles.map((e) => File(e.path)).toList();
    ref.read(imageProvider.notifier).state = imageFiles;
  }

  // Function to upload images to Firebase Storage
  Future<List<String>> uploadImages(List<File> images) async {
    List<String> imageUrls = [];
    final storage = FirebaseStorage.instance;

    try {
      for (var image in images) {
        final storageRef = storage.ref().child(
            'catering_images/${DateTime.now().millisecondsSinceEpoch}.jpg');
        final uploadTask = storageRef.putFile(image);
        final snapshot = await uploadTask.whenComplete(() {});
        final downloadUrl = await snapshot.ref.getDownloadURL();
        imageUrls.add(downloadUrl);
      }
    } catch (e) {
      throw Exception('Image upload failed: $e');
    }

    return imageUrls;
  }

  // Function to upload catering data to Firestore
  Future<void> uploadData(
    WidgetRef ref,
    String vendorId,
    List<String> imageUrls,
  ) async {
    try {
      final title = ref.read(titleProvider);
      final description = ref.read(descriptionProvider);

      // Check if all fields are filled
      if (title.isEmpty || description.isEmpty || imageUrls.isEmpty) {
        throw Exception(
            'Please fill in all fields and upload at least one image');
      }

      // Firestore collection reference
      final cateringCollection =
          FirebaseFirestore.instance.collection('vendors');

      // Add the vendor's catering service
      await cateringCollection
          .doc(vendorId)
          .collection('catering_services')
          .add({
        'title': title,
        'description': description,
        'images': imageUrls,
        'createdAt': Timestamp.now(),
      });

      // Optionally show success message
      print('Catering service uploaded successfully!');
    } catch (e) {
      throw Exception('Data upload failed: $e');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final images = ref.watch(imageProvider);
    final title = ref.watch(titleProvider);
    final description = ref.watch(descriptionProvider);

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(title: const Text('Upload Catering Data')),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title Field
              TextField(
                onChanged: (value) =>
                    ref.read(titleProvider.notifier).state = value,
                decoration: const InputDecoration(
                  labelText: 'Catering Title',
                  hintText: 'Enter catering service title',
                ),
              ),
              const SizedBox(height: 16),

              // Description Field
              TextField(
                onChanged: (value) =>
                    ref.read(descriptionProvider.notifier).state = value,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Enter catering service description',
                ),
              ),
              const SizedBox(height: 16),

              // Image Selection
              ElevatedButton(
                onPressed: () => pickImages(ref),
                child: const Text('Pick Images'),
              ),
              const SizedBox(height: 16),

              // Display selected images in a horizontal list
              images.isNotEmpty
                  ? SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: images.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 8.0),
                            child: Image.file(
                              images[index],
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                            ),
                          );
                        },
                      ),
                    )
                  : const Text('No images selected.'),
              const SizedBox(height: 16),

              // Upload Button
              ElevatedButton(
                onPressed: () async {
                  if (images.isEmpty || title.isEmpty || description.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              'Please fill in all fields and select at least one image')),
                    );
                    return;
                  }

                  if (images.length > 10) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content:
                              Text('You can upload a maximum of 10 images')),
                    );
                    return;
                  }

                  try {
                    // Assuming the user is logged in and vendorId is available
                    String vendorId =
                        'vendor_user_id'; // Replace with actual user ID from authentication

                    // Upload images
                    List<String> imageUrls = await uploadImages(images);
                    // Upload data to Firestore
                    await uploadData(ref, vendorId, imageUrls);

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content:
                              Text('Catering service uploaded successfully!')),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                },
                child: const Text('Upload'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
