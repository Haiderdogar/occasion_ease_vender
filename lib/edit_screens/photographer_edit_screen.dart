import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class EditPhotographerServicesForm extends StatefulWidget {
  final String docId;

  EditPhotographerServicesForm({required this.docId});

  @override
  _EditPhotographerServicesFormState createState() =>
      _EditPhotographerServicesFormState();
}

class _EditPhotographerServicesFormState
    extends State<EditPhotographerServicesForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();

  List<File> _images = [];
  List<TimeSlot> _timeSlots = [];
  List<String> _existingImageUrls = [];

  final Map<String, TextEditingController> _servicePriceControllers = {};

  final Map<String, List<String>> serviceCategories = {
    'Event Photography': [
      'Weddings',
      'Corporate events',
      'Birthdays',
      'Anniversaries',
      'Graduations',
      'Engagement and Pre-wedding Photoshoots',
    ],
    'Portrait & Personal Photography': [
      'Family portraits',
      'Couples photoshoots',
      'Individual portraits',
      'Maternity photoshoots',
    ],
    'Commercial & Product Photography': [
      'E-commerce product photos',
      'Flat lay photography',
      'Food photography',
      'Real Estate Photography (Interior & Exterior)',
      'Commercial Photography (Advertising, branding, etc.)',
    ],
    'Specialized & Add-on Services': [
      'Photo Editing and Retouching (Basic & Advanced)',
      'Photobooth Rental (Setup, printouts, customizable strips)',
      'Destination Photography (Travel shoots for weddings or vacations)',
      'Custom Packages (Tailored services based on client needs)',
    ],
  };

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('Photographer')
          .doc(widget.docId)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;

        setState(() {
          _nameController.text = data['photographerName'];
          _locationController.text = data['location'];
          _descriptionController.text = data['description'];
          _existingImageUrls = List<String>.from(data['imageUrls']);
          _timeSlots = (data['timeSlots'] as List)
              .map((t) => TimeSlot.fromJson(t))
              .toList();

          // Load services
          (data['services'] as List).forEach((s) {
            final service = Service.fromJson(s);
            _servicePriceControllers[service.name] =
                TextEditingController(text: service.price.toString());
          });

          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading data: $e');
      setState(() {
        _isLoading = false;
      });
    }
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

  void _removeExistingImage(int index) {
    setState(() {
      _existingImageUrls.removeAt(index);
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
      final reference = storage.ref().child('photographer_images/$fileName');
      await reference.putFile(image);
      final url = await reference.getDownloadURL();
      imageUrls.add(url);
    }
    return imageUrls;
  }

  Future<void> _updateForm() async {
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

      List<String> newImageUrls = await _uploadImages();
      List<String> allImageUrls = [..._existingImageUrls, ...newImageUrls];

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
        'photographerName': _nameController.text,
        'location': _locationController.text,
        'description': _descriptionController.text,
        'services': services.map((s) => s.toJson()).toList(),
        'timeSlots': _timeSlots.map((t) => t.toJson()).toList(),
        'imageUrls': allImageUrls,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('Photographer')
          .doc(widget.docId)
          .update(data);

      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Photographer services updated successfully!')),
      );

      Navigator.of(context).pop(); // Go back to the previous screen
    } catch (e) {
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Photographer Services'),
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
              _buildTextField(_nameController, 'Photographer Name'),
              SizedBox(height: 16),
              _buildTextField(_locationController, 'Location'),
              SizedBox(height: 16),
              _buildTextField(_descriptionController, 'Description',
                  maxLines: 3),
              SizedBox(height: 24),
              _buildSectionTitle('Services'),
              ..._buildServiceCategories(),
              SizedBox(height: 24),
              _buildSectionTitle('Portfolio Images'),
              _buildImageSection(),
              SizedBox(height: 24),
              _buildSectionTitle('Availability'),
              _buildTimeSlotSection(),
              SizedBox(height: 24),
              _buildUpdateButton(),
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
        if (_existingImageUrls.isNotEmpty || _images.isNotEmpty)
          Container(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _existingImageUrls.length + _images.length,
              itemBuilder: (context, index) {
                if (index < _existingImageUrls.length) {
                  return _buildExistingImageItem(index);
                } else {
                  return _buildNewImageItem(index - _existingImageUrls.length);
                }
              },
            ),
          ),
      ],
    );
  }

  Widget _buildExistingImageItem(int index) {
    return Stack(
      children: [
        Card(
          margin: EdgeInsets.all(8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              _existingImageUrls[index],
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
            onPressed: () => _removeExistingImage(index),
          ),
        ),
      ],
    );
  }

  Widget _buildNewImageItem(int index) {
    return Stack(
      children: [
        Card(
          margin: EdgeInsets.all(8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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

  Widget _buildUpdateButton() {
    return ElevatedButton(
      onPressed: _updateForm,
      child: Text('Update Photographer Services'),
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

class Service {
  final String name;
  final double price;
  final String category;

  Service({
    required this.name,
    required this.price,
    required this.category,
  });

  // Convert Service object to JSON
  Map<String, dynamic> toJson() => {
        'name': name,
        'price': price,
        'category': category,
      };

  // Create Service object from JSON
  factory Service.fromJson(Map<String, dynamic> json) {
    return Service(
      name: json['name'],
      price: json['price'],
      category: json['category'],
    );
  }
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

  // Convert TimeSlot object to JSON
  Map<String, dynamic> toJson() => {
        'startTime': startTime,
        'endTime': endTime,
        'capacity': capacity,
      };

  // Create TimeSlot object from JSON
  factory TimeSlot.fromJson(Map<String, dynamic> json) {
    return TimeSlot(
      startTime: json['startTime'],
      endTime: json['endTime'],
      capacity: json['capacity'],
    );
  }
}
