import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class Service {
  final String name;
  final double price;
  final String category;

  Service({
    required this.name,
    required this.price,
    required this.category,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'price': price,
        'category': category,
      };
}

class TimeSlot {
  final String startTime;
  final String endTime;
  final int capacity;

  TimeSlot({
    required this.startTime,
    required this.endTime,
    required this.capacity,
  });

  Map<String, dynamic> toJson() => {
        'startTime': startTime,
        'endTime': endTime,
        'capacity': capacity,
      };
}

class BeautyParlorForm extends StatefulWidget {
  final String serviceName;

  const BeautyParlorForm({super.key, required this.serviceName});
  @override
  _BeautyParlorFormState createState() => _BeautyParlorFormState();
}

class _BeautyParlorFormState extends State<BeautyParlorForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();

  List<File> _images = [];
  List<TimeSlot> _timeSlots = [];

  final Map<String, TextEditingController> _servicePriceControllers = {};

  final Map<String, List<String>> serviceCategories = {
    'Hair Services': [
      'Haircut (Basic, Layers, Bob)',
      'Hair Coloring (Full Color, Highlights, Balayage)',
      'Hair Styling (Blow Dry, Straightening, Curls)',
      'Keratin Treatment',
      'Bridal Hair Styling (Traditional, Updos)',
    ],
    'Skin and Facial Services': [
      'Facials (Deep Cleanse, Anti-aging, Hydrating)',
      'Chemical Peels (Exfoliating, Skin Rejuvenation)',
      'Threading (Eyebrows, Upper Lip, Chin)',
      'Face Masks (Hydrating, Detoxifying)',
      'Microblading (Eyebrows)',
    ],
    'Nail Services': [
      'Manicure (Classic, Gel, French)',
      'Pedicure (Classic, Spa, Gel)',
      'Nail Art (Designs, Stamping)',
      'Nail Extensions (Acrylic, Gel)',
      'Polish Change',
    ],
    'Makeup Services': [
      'Bridal Makeup (Traditional, Airbrush, HD)',
      'Party Makeup (For Events, Celebrations)',
      'Makeup for Photoshoots',
      'Eye Makeup (Eyebrow Shaping, Eyelash Extensions)',
    ],
  };

  @override
  void initState() {
    super.initState();
    serviceCategories.forEach((category, services) {
      services.forEach((service) {
        _servicePriceControllers[service] = TextEditingController();
      });
    });
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage();

    // ignore: unnecessary_null_comparison
    if (pickedFiles != null) {
      setState(() {
        _images.addAll(pickedFiles.map((file) => File(file.path)));
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _images.removeAt(index);
    });
  }

  void _addTimeSlot(BuildContext context) {
    TimeOfDay? startTime;
    TimeOfDay? endTime;
    int capacity = 1;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Time Slot'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text('Start Time'),
              trailing: Icon(Icons.access_time),
              onTap: () async {
                final time = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.now(),
                );
                if (time != null) {
                  startTime = time;
                }
              },
            ),
            ListTile(
              title: Text('End Time'),
              trailing: Icon(Icons.access_time),
              onTap: () async {
                final time = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.now(),
                );
                if (time != null) {
                  endTime = time;
                }
              },
            ),
            TextField(
              decoration: InputDecoration(labelText: 'Capacity'),
              keyboardType: TextInputType.number,
              onChanged: (value) => capacity = int.tryParse(value) ?? 1,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (startTime != null && endTime != null) {
                setState(() {
                  _timeSlots.add(TimeSlot(
                    startTime: startTime!.format(context),
                    endTime: endTime!.format(context),
                    capacity: capacity,
                  ));
                });
                Navigator.pop(context);
              }
            },
            child: Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<List<String>> _uploadImages() async {
    List<String> imageUrls = [];
    final storage = FirebaseStorage.instance;
    for (var image in _images) {
      final fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final reference = storage.ref().child('${widget.serviceName}/$fileName');
      await reference.putFile(image);
      final url = await reference.getDownloadURL();
      imageUrls.add(url);
    }
    return imageUrls;
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(child: CircularProgressIndicator());
        },
      );

      // Upload images and get URLs
      List<String> imageUrls = await _uploadImages();

      // Collect all services with their prices
      List<Service> services = [];
      serviceCategories.forEach((category, serviceList) {
        serviceList.forEach((serviceName) {
          final priceText = _servicePriceControllers[serviceName]?.text ?? '0';
          final price = double.tryParse(priceText) ?? 0.0;
          if (price > 0) {
            services.add(Service(
              name: serviceName,
              price: price,
              category: category,
            ));
          }
        });
      });

      final data = {
        'userId': user.uid,
        'parlorName': _nameController.text,
        'location': _locationController.text,
        'description': _descriptionController.text,
        'services': services.map((s) => s.toJson()).toList(),
        'timeSlots': _timeSlots.map((t) => t.toJson()).toList(),
        'imageUrls': imageUrls,
        'createdAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance.collection(widget.serviceName).add(data);

      // Hide loading indicator
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${widget.serviceName} added successfully!')),
      );
    } catch (e) {
      // Hide loading indicator
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add ${widget.serviceName}'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Name of ${widget.serviceName}',
                border: OutlineInputBorder(),
              ),
              validator: (value) => value?.isEmpty ?? true
                  ? 'Please enter ${widget.serviceName} name'
                  : null,
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _locationController,
              decoration: InputDecoration(
                labelText: 'Location',
                border: OutlineInputBorder(),
              ),
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Please enter location' : null,
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Please enter description' : null,
            ),
            SizedBox(height: 24),
            Text(
              'Services',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            ...serviceCategories.entries.map((category) => Card(
                  margin: EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          category.key,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: category.value.length,
                        itemBuilder: (context, index) {
                          final service = category.value[index];
                          return Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: Text(service),
                                ),
                                SizedBox(width: 16),
                                Expanded(
                                  child: TextFormField(
                                    controller:
                                        _servicePriceControllers[service],
                                    decoration: InputDecoration(
                                      labelText: 'Price',
                                      prefixText: '₹',
                                      border: OutlineInputBorder(),
                                    ),
                                    keyboardType: TextInputType.number,
                                    validator: (value) {
                                      if (value?.isEmpty ?? true)
                                        return 'Required';
                                      if (double.tryParse(value!) == null) {
                                        return 'Invalid price';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                )),
            SizedBox(height: 24),
            Text(
              'Images',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            ElevatedButton.icon(
              onPressed: _pickImages,
              icon: Icon(Icons.add_photo_alternate),
              label: Text('Add Images'),
            ),
            if (_images.isNotEmpty)
              Container(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _images.length,
                  itemBuilder: (context, index) => Stack(
                    children: [
                      Padding(
                        padding: EdgeInsets.all(8),
                        child: Image.file(
                          _images[index],
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        right: 0,
                        top: 0,
                        child: IconButton(
                          icon: Icon(Icons.close),
                          onPressed: () => _removeImage(index),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            SizedBox(height: 24),
            Text(
              'Time Slots',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            ElevatedButton.icon(
              onPressed: () => _addTimeSlot(context),
              icon: Icon(Icons.access_time),
              label: Text('Add Time Slot'),
            ),
            ..._timeSlots.map((slot) => Card(
                  margin: EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    leading: Icon(Icons.access_time),
                    title: Text('${slot.startTime} - ${slot.endTime}'),
                    subtitle: Text('Capacity: ${slot.capacity}'),
                    trailing: IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: () {
                        setState(() {
                          _timeSlots.remove(slot);
                        });
                      },
                    ),
                  ),
                )),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _submitForm,
              child: Text('Add Services'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _servicePriceControllers.values
        .forEach((controller) => controller.dispose());
    super.dispose();
  }
}
