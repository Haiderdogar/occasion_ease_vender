import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import 'package:occasionease/data_upload/marriage_hall_data_uploading/service_notifier.dart';

class AddServiceScreen extends ConsumerStatefulWidget {
  final String selectedServices;
  const AddServiceScreen(this.selectedServices, {super.key});

  @override
  ConsumerState<AddServiceScreen> createState() => _AddServiceScreenState();
}

class _AddServiceScreenState extends ConsumerState<AddServiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _locationController = TextEditingController();
  String _serviceType = 'Asian';
  final List<String> _selectedServices = [];
  final List<File> _selectedImages = [];

  late List<String> _services;

  @override
  void initState() {
    super.initState();
    _services = _getServicesBasedOnSelection(widget.selectedServices);
  }

  List<String> _getServicesBasedOnSelection(String category) {
    switch (category) {
      case 'Beauty Parlors':
      case 'Saloons':
        return [
          'Hair Services',
          'Skin Care Services',
          'Makeup Services',
          'Nail Services',
          'Eyelash and Eyebrow Services',
          'Specialized Services',
        ];
      case 'Marriage Halls':
      case 'Farm Houses':
      case 'Catering':
        return [
          'Venue Rental',
          'Catering Services',
          'Decor and Floral Arrangements',
          'Audio-Visual Equipment',
          'Photography and Videography',
          'Additional Amenities',
        ];
      case 'Photographer':
        return [
          'Simple Photo Shot',
          'Wedding Ceremony',
          'Birthday Event',
          'Party Event',
        ];
      default:
        return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final serviceState = ref.watch(serviceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Service'),
        backgroundColor: Colors.blue,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Enter Service Name',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'Please enter service name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Enter Description',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'Please enter description';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Enter Location',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'Please enter a location';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.all(16),
              ),
              onPressed: _pickImages,
              icon: const Icon(Icons.image),
              label: const Text('Select Images'),
            ),
            if (_selectedImages.isNotEmpty) ...[
              const SizedBox(height: 16),
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedImages.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Stack(
                        children: [
                          Image.file(
                            _selectedImages[index],
                            height: 100,
                            width: 100,
                            fit: BoxFit.cover,
                          ),
                          Positioned(
                            right: 0,
                            child: IconButton(
                              icon:
                                  const Icon(Icons.close, color: Colors.white),
                              onPressed: () => setState(
                                () => _selectedImages.removeAt(index),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 16),
            TextFormField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Price',
                prefixText: 'Rs.',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'Please enter price';
                }
                if (double.tryParse(value!) == null) {
                  return 'Please enter valid price';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _serviceType,
              decoration: const InputDecoration(
                labelText: 'Service Type',
                border: OutlineInputBorder(),
              ),
              items: ['Asian', 'Western'].map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type),
                );
              }).toList(),
              onChanged: (value) => setState(() => _serviceType = value!),
            ),
            const SizedBox(height: 16),
            const Text('Select Services:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ...List.generate(_services.length, (index) {
              final service = _services[index];
              return CheckboxListTile(
                title: Text(service),
                value: _selectedServices.contains(service),
                onChanged: (checked) {
                  setState(() {
                    if (checked ?? false) {
                      _selectedServices.add(service);
                    } else {
                      _selectedServices.remove(service);
                    }
                  });
                },
              );
            }),
            const SizedBox(height: 24),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                ),
                onPressed: () {
                  serviceState.isLoading
                      ? null
                      : _submitForm(
                          selectedServiesName: widget.selectedServices);
                },
                child: serviceState.isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Upload Services',
                        style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final images = await picker.pickMultiImage();
    // ignore: unnecessary_null_comparison
    if (images != null) {
      setState(() {
        _selectedImages.addAll(images.map((image) => File(image.path)));
      });
    }
  }

  Future<void> _submitForm({required String selectedServiesName}) async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one image')),
      );
      return;
    }
    if (_selectedServices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one service')),
      );
      return;
    }

    try {
      await ref.read(serviceProvider.notifier).addService(
          name: _nameController.text,
          description: _descriptionController.text,
          price: double.parse(_priceController.text),
          serviceType: _serviceType,
          selectedServices: _selectedServices,
          images: _selectedImages,
          location: _locationController.text,
          serviceName: selectedServiesName);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Service added successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _locationController.dispose();
    super.dispose();
  }
}
