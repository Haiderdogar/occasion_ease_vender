import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:occasionease/data_upload/mariage_hall/add_time_slot.dart';

class AddMarriageHallScreen extends StatefulWidget {
  final String serviceName;
  const AddMarriageHallScreen({super.key, required this.serviceName});

  @override
  // ignore: library_private_types_in_public_api
  _AddMarriageHallScreenState createState() => _AddMarriageHallScreenState();
}

class _AddMarriageHallScreenState extends State<AddMarriageHallScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _maxCapacityController = TextEditingController();
  final _minCapacityController = TextEditingController();
  final _pricePerSeatController = TextEditingController();

  // ignore: prefer_final_fields
  List<TimeSlot> _timeSlots = [];
  List<AdditionalService> _additionalServices = [
    AdditionalService(name: 'Decor', price: 0),
    AdditionalService(name: 'Catering', price: 0),
    AdditionalService(name: 'DJ', price: 0),
    AdditionalService(name: 'Photography', price: 0),
    AdditionalService(name: 'Air Conditioning/Heating', price: 0),
  ];

  // ignore: prefer_final_fields
  List<File> _images = [];
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Add ${widget.serviceName}',
            style: const TextStyle(color: Colors.blue)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.blue))
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
                    _buildTextField(_maxCapacityController, 'Maximum Capacity',
                        Icons.people,
                        isNumber: true),
                    _buildTextField(_minCapacityController, 'Minimum Capacity',
                        Icons.people_outline,
                        isNumber: true),
                    _buildTextField(_pricePerSeatController,
                        'Price per Seat (₹)', Icons.attach_money,
                        isNumber: true),
                    const SizedBox(height: 20),
                    _buildSectionTitle('Images'),
                    _buildImageUploadSection(),
                    const SizedBox(height: 20),
                    _buildSectionTitle('Time Slots'),
                    _buildTimeSlotsList(),
                    ElevatedButton.icon(
                      onPressed: _showAddTimeSlotDialog,
                      icon: const Icon(Icons.add, color: Colors.blue),
                      label: const Text('Add Time Slot',
                          style: TextStyle(color: Colors.blue)),
                    ),
                    const SizedBox(height: 20),
                    _buildSectionTitle('Additional Services'),
                    ..._buildAdditionalServicesList(),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double
                          .infinity, // Makes the button stretch to the full width
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Colors.blue, // Set the background color
                          foregroundColor:
                              Colors.white, // Set the text color (optional)
                          padding: const EdgeInsets.symmetric(
                              vertical: 16), // Adjust padding
                          shape: RoundedRectangleBorder(
                            // Add rounded corners
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: _submitForm,
                        child: Text(
                          'Add ${widget.serviceName}',
                          style: const TextStyle(
                            fontSize: 16, // Adjust the font size if needed
                            fontWeight: FontWeight
                                .bold, // Make the text bold (optional)
                          ),
                        ),
                      ),
                    ),
                  ],
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
        style: const TextStyle(
            fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue),
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller, String label, IconData icon,
      {bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(
            color: Colors.grey, // Label color
            fontWeight: FontWeight.w500, // Slightly bold
          ),
          prefixIcon: Icon(icon, color: Colors.blue),
          filled: true, // Adds a background color
          fillColor: Colors.white, // Light grey background
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(
                color: Colors.blue, width: 2), // Blue border when focused
            borderRadius: BorderRadius.circular(8), // Rounded corners
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(
                color: Colors.grey, width: 1), // Grey border when not focused
            borderRadius: BorderRadius.circular(8), // Rounded corners
          ),
          errorBorder: OutlineInputBorder(
            borderSide: const BorderSide(
                color: Colors.red, width: 1), // Red border for errors
            borderRadius: BorderRadius.circular(8), // Rounded corners
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderSide: const BorderSide(
                color: Colors.red,
                width: 2), // Red border when focused on error
            borderRadius: BorderRadius.circular(8), // Rounded corners
          ),
          contentPadding: const EdgeInsets.symmetric(
              vertical: 16, horizontal: 16), // Adjust padding
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
    );
  }

  Widget _buildImageUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ElevatedButton.icon(
          onPressed: _pickImages,
          icon: const Icon(Icons.add_photo_alternate, color: Colors.blue),
          label: const Text('Add Images', style: TextStyle(color: Colors.blue)),
        ),
        const SizedBox(height: 10),
        if (_images.isNotEmpty)
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _images.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Stack(
                    children: [
                      Image.file(
                        _images[index],
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () => _removeImage(index),
                          child: Container(
                            color: Colors.black54,
                            child: const Icon(Icons.close,
                                color: Colors.white, size: 20),
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
    );
  }

  Widget _buildTimeSlotsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ..._timeSlots
            .map((slot) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  color: Colors.blue[50],
                  child: ExpansionTile(
                    leading: const Icon(Icons.access_time, color: Colors.blue),
                    title: Text('${slot.startTime} - ${slot.endTime}'),
                    subtitle: Text('Events: ${slot.maxEvents}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.blue),
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
                              child: const Text('Edit Slot'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ))
            // ignore: unnecessary_to_list_in_spreads
            .toList(),
      ],
    );
  }

  List<Widget> _buildAdditionalServicesList() {
    return _additionalServices
        .map((service) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                        child: Text(service.name,
                            style: const TextStyle(fontSize: 16))),
                    SizedBox(
                      width: 100,
                      child: TextFormField(
                        initialValue: service.price.toString(),
                        decoration: const InputDecoration(
                          labelText: 'Price (₹)',
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          service.price = double.tryParse(value) ?? 0;
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Required';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Invalid';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ))
        .toList();
  }

  void _showAddTimeSlotDialog() async {
    final result = await showDialog<TimeSlot>(
      context: context,
      builder: (context) => const TimeSlotDialog(),
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

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      if (_images.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please add at least one image')),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        User? user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          throw Exception('No user logged in');
        }

        List<String> imageUrls = await _uploadImages();

        Map<String, dynamic> hallData = {
          'userId': FirebaseAuth.instance.currentUser!.uid,
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
          'imageUrls': imageUrls,
        };

        await FirebaseFirestore.instance
            .collection(widget.serviceName)
            .add(hallData);

        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.serviceName} added successfully'),
            backgroundColor: Colors.blue,
          ),
        );

        _formKey.currentState!.reset();
        setState(() {
          _timeSlots.clear();
          _additionalServices = [
            AdditionalService(name: 'Decor', price: 0),
            AdditionalService(name: 'Catering', price: 0),
            AdditionalService(name: 'DJ', price: 0),
            AdditionalService(name: 'Photography', price: 0),
            AdditionalService(name: 'Air Conditioning/Heating', price: 0),
          ];
          _images.clear();
        });
      } catch (e) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
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
