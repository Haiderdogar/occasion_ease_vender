import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

import 'package:occasionease/data_upload/beauty_polor/beautypoloar.dart';

class EditBeautyParlorForm extends StatefulWidget {
  final String serviceName;
  final String documentId;

  const EditBeautyParlorForm({
    Key? key,
    required this.serviceName,
    required this.documentId,
  }) : super(key: key);

  @override
  _EditBeautyParlorFormState createState() => _EditBeautyParlorFormState();
}

class _EditBeautyParlorFormState extends State<EditBeautyParlorForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();

  List<File> _images = [];
  List<TimeSlot> _timeSlots = [];
  List<String> _existingImageUrls = [];

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
    _loadData();
  }

  Future<void> _loadData() async {
    final doc = await FirebaseFirestore.instance
        .collection(widget.serviceName)
        .doc(widget.documentId)
        .get();

    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      _nameController.text = data['parlorName'];
      _locationController.text = data['location'];
      _descriptionController.text = data['description'];
      _existingImageUrls = List<String>.from(data['imageUrls']);

      final services = List<Map<String, dynamic>>.from(data['services']);
      services.forEach((service) {
        _servicePriceControllers[service['name']] =
            TextEditingController(text: service['price'].toString());
      });

      final timeSlots = List<Map<String, dynamic>>.from(data['timeSlots']);
      _timeSlots = timeSlots
          .map((slot) => TimeSlot(
                startTime: slot['startTime'],
                endTime: slot['endTime'],
                capacity: slot['capacity'],
              ))
          .toList();

      setState(() {});
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
      final reference = storage.ref().child('${widget.serviceName}/$fileName');
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
          return const Center(child: CircularProgressIndicator());
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
        'parlorName': _nameController.text,
        'location': _locationController.text,
        'description': _descriptionController.text,
        'services': services.map((s) => s.toJson()).toList(),
        'timeSlots': _timeSlots.map((t) => t.toJson()).toList(),
        'imageUrls': allImageUrls,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection(widget.serviceName)
          .doc(widget.documentId)
          .update(data);

      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${widget.serviceName} updated successfully!')),
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
        title: Text('Edit ${widget.serviceName}'),
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
              _buildTextField(_nameController, 'Name of ${widget.serviceName}'),
              SizedBox(height: 16),
              _buildTextField(_locationController, 'Location'),
              SizedBox(height: 16),
              _buildTextField(_descriptionController, 'Description',
                  maxLines: 3),
              SizedBox(height: 24),
              _buildSectionTitle('Services'),
              ..._buildServiceCategories(),
              SizedBox(height: 24),
              _buildSectionTitle('Images'),
              _buildImageSection(),
              SizedBox(height: 24),
              _buildSectionTitle('Time Slots'),
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
                  return Stack(
                    children: [
                      Card(
                        margin: EdgeInsets.all(8),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
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
                } else {
                  final imageIndex = index - _existingImageUrls.length;
                  return Stack(
                    children: [
                      Card(
                        margin: EdgeInsets.all(8),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            _images[imageIndex],
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
                          onPressed: () => _removeImage(imageIndex),
                        ),
                      ),
                    ],
                  );
                }
              },
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
      child: Text('Update Services'),
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
