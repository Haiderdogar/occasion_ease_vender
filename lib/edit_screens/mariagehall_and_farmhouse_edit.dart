import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:occasionease/data_upload/mariage_hall/add_time_slot.dart';

class EditMarriageHallScreen extends StatefulWidget {
  final String serviceName;
  final String documentId;

  const EditMarriageHallScreen({
    Key? key,
    required this.serviceName,
    required this.documentId,
  }) : super(key: key);

  @override
  _EditMarriageHallScreenState createState() => _EditMarriageHallScreenState();
}

class _EditMarriageHallScreenState extends State<EditMarriageHallScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _maxCapacityController = TextEditingController();
  final _minCapacityController = TextEditingController();
  final _pricePerSeatController = TextEditingController();

  List<TimeSlot> _timeSlots = [];
  List<AdditionalService> _additionalServices = [];
  List<File> _images = [];
  List<String> _existingImageUrls = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final doc = await FirebaseFirestore.instance
          .collection(widget.serviceName)
          .doc(widget.documentId)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        _nameController.text = data['name'];
        _locationController.text = data['location'];
        _maxCapacityController.text = data['maxCapacity'].toString();
        _minCapacityController.text = data['minCapacity'].toString();
        _pricePerSeatController.text = data['pricePerSeat'].toString();
        _existingImageUrls = List<String>.from(data['imageUrls']);

        _timeSlots = (data['timeSlots'] as List)
            .map((slot) => TimeSlot(
                  startTime: slot['startTime'],
                  endTime: slot['endTime'],
                  price: slot['price'],
                  maxEvents: slot['maxEvents'],
                ))
            .toList();

        _additionalServices = (data['additionalServices'] as List)
            .map((service) => AdditionalService(
                  name: service['name'],
                  price: service['price'],
                ))
            .toList();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error fetching data: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
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
        child: _isLoading
            ? Center(child: CircularProgressIndicator(color: Colors.blue[700]))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('${widget.serviceName} Details'),
                      _buildTextField(_nameController,
                          '${widget.serviceName} Name', Icons.business),
                      _buildTextField(
                          _locationController, 'Location', Icons.location_on),
                      _buildTextField(_maxCapacityController,
                          'Maximum Capacity', Icons.people,
                          isNumber: true),
                      _buildTextField(_minCapacityController,
                          'Minimum Capacity', Icons.people_outline,
                          isNumber: true),
                      _buildTextField(_pricePerSeatController,
                          'Price per Seat (Rs)', Icons.attach_money,
                          isNumber: true),
                      const SizedBox(height: 20),
                      _buildSectionTitle('Images'),
                      _buildImageUploadSection(),
                      const SizedBox(height: 20),
                      _buildSectionTitle('Time Slots'),
                      _buildTimeSlotsList(),
                      _buildAddTimeSlotButton(),
                      const SizedBox(height: 20),
                      _buildSectionTitle('Additional Services'),
                      ..._buildAdditionalServicesList(),
                      const SizedBox(height: 20),
                      _buildSubmitButton(),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Text(
        title,
        style: TextStyle(
            fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue[700]),
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller, String label, IconData icon,
      {bool isNumber = false}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: TextFormField(
          controller: controller,
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(color: Colors.blue[700]),
            prefixIcon: Icon(icon, color: Colors.blue[300]),
            border: InputBorder.none,
          ),
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter $label';
            }
            if (isNumber && double.tryParse(value) == null) {
              return 'Please enter a valid number';
            }
            return null;
          },
        ),
      ),
    );
  }

  Widget _buildImageUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ElevatedButton.icon(
          onPressed: _pickImages,
          icon: Icon(Icons.add_photo_alternate, color: Colors.blue[700]),
          label: Text('Add Images', style: TextStyle(color: Colors.blue[700])),
          style: ElevatedButton.styleFrom(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        const SizedBox(height: 10),
        if (_images.isNotEmpty || _existingImageUrls.isNotEmpty)
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _images.length + _existingImageUrls.length,
              itemBuilder: (context, index) {
                if (index < _existingImageUrls.length) {
                  return Stack(
                    children: [
                      Card(
                        margin: const EdgeInsets.all(4),
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
                        top: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () => _removeExistingImage(index),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.close,
                                color: Colors.white, size: 20),
                          ),
                        ),
                      ),
                    ],
                  );
                } else {
                  final imageIndex = index - _existingImageUrls.length;
                  return Stack(
                    children: [
                      Card(
                        margin: const EdgeInsets.all(4),
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
                        top: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () => _removeImage(imageIndex),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.close,
                                color: Colors.white, size: 20),
                          ),
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

  Widget _buildTimeSlotsList() {
    return Column(
      children: _timeSlots
          .map((slot) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: ExpansionTile(
                  leading: Icon(Icons.access_time, color: Colors.blue[700]),
                  title: Text('${slot.startTime} - ${slot.endTime}'),
                  subtitle: Text('Events: ${slot.maxEvents}'),
                  trailing: IconButton(
                    icon: Icon(Icons.delete, color: Colors.blue[300]),
                    onPressed: () => _removeTimeSlot(slot),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Price: ₹${slot.price}'),
                          const SizedBox(height: 8),
                          Text('Max Events: ${slot.maxEvents}'),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: () => _editTimeSlot(slot),
                            child: Text('Edit Slot'),
                            style: ElevatedButton.styleFrom(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ))
          .toList(),
    );
  }

  Widget _buildAddTimeSlotButton() {
    return ElevatedButton.icon(
      onPressed: _showAddTimeSlotDialog,
      icon: Icon(Icons.add, color: Colors.blue[700]),
      label: Text('Add Time Slot', style: TextStyle(color: Colors.blue[700])),
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  List<Widget> _buildAdditionalServicesList() {
    return _additionalServices
        .map((service) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(service.name,
                          style:
                              TextStyle(fontSize: 16, color: Colors.blue[700])),
                    ),
                    SizedBox(
                      width: 100,
                      child: TextFormField(
                        initialValue: service.price.toString(),
                        decoration: InputDecoration(
                          labelText: 'Price (Rs)',
                          labelStyle: TextStyle(color: Colors.blue[300]),
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          service.price = double.tryParse(value) ?? 0;
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ))
        .toList();
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: _updateForm,
        child: Text(
          'Update ${widget.serviceName}',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  void _showAddTimeSlotDialog() async {
    final result = await showDialog<TimeSlot>(
      context: context,
      builder: (context) => TimeSlotDialog(),
    );

    if (result != null) {
      setState(() {
        _timeSlots.add(result);
      });
    }
  }

  void _editTimeSlot(TimeSlot slot) async {
    final result = await showDialog<TimeSlot>(
      context: context,
      builder: (context) => TimeSlotDialog(initialSlot: slot),
    );

    if (result != null) {
      setState(() {
        final index = _timeSlots.indexOf(slot);
        _timeSlots[index] = result;
      });
    }
  }

  void _removeTimeSlot(TimeSlot slot) {
    setState(() {
      _timeSlots.remove(slot);
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

  void _removeExistingImage(int index) {
    setState(() {
      _existingImageUrls.removeAt(index);
    });
  }

  Future<List<String>> _uploadImages() async {
    List<String> imageUrls = [];
    final storage = FirebaseStorage.instance;

    for (var image in _images) {
      final ref = storage.ref().child(
          '${widget.serviceName}/${DateTime.now().toIso8601String()}_${image.path.split('/').last}');
      final uploadTask = ref.putFile(image);
      final snapshot = await uploadTask.whenComplete(() {});
      final url = await snapshot.ref.getDownloadURL();
      imageUrls.add(url);
    }

    return imageUrls;
  }

  void _updateForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        User? user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          throw Exception('No user logged in');
        }

        List<String> newImageUrls = await _uploadImages();
        List<String> allImageUrls = [..._existingImageUrls, ...newImageUrls];

        Map<String, dynamic> hallData = {
          'userId': user.uid,
          'name': _nameController.text,
          'location': _locationController.text,
          'maxCapacity': int.parse(_maxCapacityController.text),
          'minCapacity': int.parse(_minCapacityController.text),
          'pricePerSeat': double.parse(_pricePerSeatController.text),
          'timeSlots': _timeSlots
              .map((slot) => {
                    'startTime': slot.startTime,
                    'endTime': slot.endTime,
                    'price': slot.price,
                    'maxEvents': slot.maxEvents,
                  })
              .toList(),
          'additionalServices': _additionalServices
              .map((service) => {
                    'name': service.name,
                    'price': service.price,
                  })
              .toList(),
          'imageUrls': allImageUrls,
        };

        await FirebaseFirestore.instance
            .collection(widget.serviceName)
            .doc(widget.documentId)
            .update(hallData);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('${widget.serviceName} updated successfully'),
              backgroundColor: Colors.green),
        );

        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}

class AdditionalService {
  final String name;
  double price;

  AdditionalService({required this.name, required this.price});
}
