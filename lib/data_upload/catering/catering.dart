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

class CateringServicesForm extends StatefulWidget {
  @override
  _CateringServicesFormState createState() => _CateringServicesFormState();
}

class _CateringServicesFormState extends State<CateringServicesForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();

  List<File> _images = [];
  List<TimeSlot> _timeSlots = [];

  final Map<String, TextEditingController> _servicePriceControllers = {};

  final Map<String, List<String>> serviceCategories = {
    'Event Planning & Coordination': [
      'Event Planning and Coordination',
      'Dietary Accommodation Services',
      'Event Staffing (Security, Ushers, etc.)',
    ],
    'Setup & Equipment Rentals': [
      'Table Setup and Decoration',
      'Rentals (Furniture & Equipment)',
      'Food Warmers and Chafing Dishes',
      'Delivery and Transport Services',
    ],
    'Service & Clean-Up': [
      'Service Style Options',
      'Mobile Bar Services',
      'Beverage Catering',
      'Waitstaff and Servers',
      'Clean-Up Services',
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
      final reference = storage.ref().child('catering_images/$fileName');
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

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Center(child: CircularProgressIndicator());
        },
      );

      List<String> imageUrls = await _uploadImages();

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
        'cateringCompanyName': _nameController.text,
        'location': _locationController.text,
        'description': _descriptionController.text,
        'services': services.map((s) => s.toJson()).toList(),
        'timeSlots': _timeSlots.map((t) => t.toJson()).toList(),
        'imageUrls': imageUrls,
        'createdAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance.collection('Catering').add(data);

      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Catering services added successfully!')),
      );
    } catch (e) {
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
        title: Text('Add Catering Services'),
        backgroundColor: Colors.blue[100],
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue[50]!, Colors.white],
          ),
        ),
        child: Form(
          key: _formKey,
          child: ListView(
            padding: EdgeInsets.all(16),
            children: [
              _buildTextField(_nameController, 'Catering Company Name'),
              SizedBox(height: 16),
              _buildTextField(_locationController, 'Location'),
              SizedBox(height: 16),
              _buildTextField(_descriptionController, 'Description',
                  maxLines: 3),
              SizedBox(height: 24),
              _buildSectionTitle('Services'),
              ..._buildServiceCategories(),
              SizedBox(height: 24),
              _buildSectionTitle('Menu Images'),
              _buildImageSection(),
              SizedBox(height: 24),
              _buildSectionTitle('Availability'),
              _buildTimeSlotSection(),
              SizedBox(height: 24),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {int maxLines = 1}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: TextFormField(
          controller: controller,
          decoration: InputDecoration(
            labelText: label,
            border: InputBorder.none,
          ),
          maxLines: maxLines,
          validator: (value) =>
              value?.isEmpty ?? true ? 'Please enter $label' : null,
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: TextStyle(
            fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue[700]),
      ),
    );
  }

  List<Widget> _buildServiceCategories() {
    return serviceCategories.entries
        .map((category) => Card(
              margin: EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: ExpansionTile(
                title: Text(
                  category.key,
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.blue[700]),
                ),
                children: category.value
                    .map((service) => _buildServiceItem(service))
                    .toList(),
              ),
            ))
        .toList();
  }

  Widget _buildServiceItem(String service) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(service, style: TextStyle(fontSize: 16)),
          ),
          SizedBox(width: 16),
          Expanded(
            child: TextFormField(
              controller: _servicePriceControllers[service],
              decoration: InputDecoration(
                labelText: 'Price',
                prefixText: 'Rs-',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              keyboardType: TextInputType.number,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageSection() {
    return Column(
      children: [
        ElevatedButton.icon(
          onPressed: _pickImages,
          icon: Icon(Icons.add_photo_alternate),
          label: Text('Add Images'),
          style: ElevatedButton.styleFrom(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        if (_images.isNotEmpty)
          Container(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _images.length,
              itemBuilder: (context, index) => Stack(
                children: [
                  Card(
                    margin: EdgeInsets.all(8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        _images[index],
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: IconButton(
                      icon: Icon(Icons.close, color: Colors.white),
                      onPressed: () => _removeImage(index),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTimeSlotSection() {
    return Column(
      children: [
        ElevatedButton.icon(
          onPressed: () => _addTimeSlot(context),
          icon: Icon(Icons.access_time),
          label: Text('Add Time Slot'),
          style: ElevatedButton.styleFrom(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        ..._timeSlots.map((slot) => Card(
              margin: EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: Icon(Icons.access_time, color: Colors.blue[700]),
                title: Text('${slot.startTime} - ${slot.endTime}'),
                subtitle: Text('Capacity: ${slot.capacity}'),
                trailing: IconButton(
                  icon: Icon(Icons.delete, color: Colors.blue[300]),
                  onPressed: () {
                    setState(() {
                      _timeSlots.remove(slot);
                    });
                  },
                ),
              ),
            )),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: _submitForm,
      child: Text('Add Catering Services'),
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
