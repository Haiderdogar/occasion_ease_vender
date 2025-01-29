import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:occasionease/data_upload/beauty_polor/beautypoloar.dart';
import 'package:occasionease/data_upload/catering/catering.dart';
import 'package:occasionease/data_upload/mariage_hall/hall_data_upload.dart';
import 'package:occasionease/data_upload/photographer/photographer.dart';
import 'package:occasionease/edit_screens/catering_edit_screen.dart';
import 'package:occasionease/edit_screens/mariagehall_and_farmhouse_edit.dart';
import 'package:occasionease/edit_screens/photographer_edit_screen.dart';
import 'package:occasionease/edit_screens/saloon_and_parlar_edit.dart';
import 'package:occasionease/stripe_payment/payment.dart';

class ServicesViewScreen extends StatelessWidget {
  final String serviceName;

  const ServicesViewScreen({Key? key, required this.serviceName})
      : super(key: key);

  void _navigateToNextScreen(BuildContext context, String serviceName) {
    Widget nextScreen;
    switch (serviceName) {
      case 'Beauty Parlors':
      case 'Saloons':
        nextScreen = BeautyParlorForm(serviceName: serviceName);
        break;
      case 'Marriage Halls':
      case 'Farm Houses':
        nextScreen = AddMarriageHallScreen(serviceName: serviceName);
        break;
      case 'Photographer':
        nextScreen = PhotographerServicesForm();
        break;
      case 'Catering':
        nextScreen = CateringServicesForm();
        break;
      default:
        return;
    }
    Navigator.push(
        context, MaterialPageRoute(builder: (context) => nextScreen));
  }

  Stream<List<ServiceModel>> _streamServices(
      String serviceName, String userId) {
    return FirebaseFirestore.instance
        .collection(serviceName)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ServiceModel.fromFirestore(doc, serviceName))
            .toList());
  }

  Future<void> _deleteService(String serviceName, String documentId) async {
    await FirebaseFirestore.instance
        .collection(serviceName)
        .doc(documentId)
        .delete();
  }

  Future<bool> _checkIfPromotionExists(String serviceName, String docId) async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final snapshot = await FirebaseFirestore.instance
        .collection('promotion_banner')
        .where('userId', isEqualTo: userId)
        .where('docId', isEqualTo: docId)
        .get();
    return snapshot.docs.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final String userId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: Text(serviceName),
        backgroundColor: Colors.blue[700],
        elevation: 0,
      ),
      body: Container(
        color: Colors.blue[50],
        child: StreamBuilder<List<ServiceModel>>(
          stream: _streamServices(serviceName, userId),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                  child: Text('Error: ${snapshot.error}',
                      style: TextStyle(color: Colors.blue[700])));
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                  child: CircularProgressIndicator(color: Colors.blue));
            }

            final services = snapshot.data ?? [];

            if (services.isEmpty) {
              return Center(
                  child: Text('No services found.',
                      style: TextStyle(color: Colors.blue[700])));
            }

            return ListView.builder(
              itemCount: services.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(12)),
                          child: Image.network(
                            services[index].imageUrl,
                            height: 150,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                services[index].name,
                                style: TextStyle(
                                    color: Colors.blue[700],
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildActionButton(
                                      icon: Icons.edit,
                                      label: 'Edit',
                                      color: Colors.blue,
                                      onPressed: () {
                                        if (serviceName == 'Catering') {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  EditCateringServicesForm(
                                                      docId:
                                                          services[index].id),
                                            ),
                                          );
                                        } else if (serviceName ==
                                            'Photographer') {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  EditPhotographerServicesForm(
                                                      docId:
                                                          services[index].id),
                                            ),
                                          );
                                        } else if (serviceName ==
                                                'Marriage Halls' ||
                                            serviceName == 'Farm Houses') {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  EditMarriageHallScreen(
                                                serviceName: serviceName,
                                                documentId: services[index].id,
                                              ),
                                            ),
                                          );
                                        } else if (serviceName ==
                                                'Beauty Parlors' ||
                                            serviceName == 'Saloons') {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  EditBeautyParlorForm(
                                                serviceName: serviceName,
                                                documentId: services[index].id,
                                              ),
                                            ),
                                          );
                                        }
                                        ;
                                      },
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: FutureBuilder<bool>(
                                      future: _checkIfPromotionExists(
                                          serviceName, services[index].id),
                                      builder: (context, promoSnapshot) {
                                        if (promoSnapshot.connectionState ==
                                            ConnectionState.waiting) {
                                          return const Center(
                                              child: CircularProgressIndicator(
                                                  color: Colors.blue));
                                        }
                                        final isPromoted =
                                            promoSnapshot.data ?? false;
                                        return _buildActionButton(
                                          icon: Icons.star,
                                          label: isPromoted
                                              ? 'Promoted'
                                              : 'Promote',
                                          color: isPromoted
                                              ? Colors.grey
                                              : Colors.green,
                                          onPressed: isPromoted
                                              ? null
                                              : () {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) =>
                                                          StripePayment(
                                                        docId:
                                                            services[index].id,
                                                        serviceName:
                                                            serviceName,
                                                      ),
                                                    ),
                                                  );
                                                },
                                        );
                                      },
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: _buildActionButton(
                                      icon: Icons.delete,
                                      label: 'Delete',
                                      color: Colors.red,
                                      onPressed: () async {
                                        bool? confirmDelete = await showDialog(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return AlertDialog(
                                              title: Text('Confirm Delete'),
                                              content: Text(
                                                  'Are you sure you want to delete this service?'),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                          context, false),
                                                  child: Text('Cancel'),
                                                ),
                                                ElevatedButton(
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                          context, true),
                                                  child: Text('Delete'),
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                    backgroundColor: Colors.red,
                                                    foregroundColor:
                                                        Colors.white,
                                                  ),
                                                ),
                                              ],
                                            );
                                          },
                                        );

                                        if (confirmDelete == true) {
                                          await _deleteService(
                                              serviceName, services[index].id);
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToNextScreen(context, serviceName),
        label: Text('Add $serviceName'),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.blue[700],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}

class ServiceModel {
  final String id;
  final String name;
  final String imageUrl;

  ServiceModel({required this.id, required this.name, required this.imageUrl});

  factory ServiceModel.fromFirestore(DocumentSnapshot doc, String serviceName) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    String fieldName;
    switch (serviceName) {
      case 'Beauty Parlors':
      case 'Saloons':
        fieldName = 'parlorName';
        break;
      case 'Photographer':
        fieldName = 'photographerName';
        break;
      default:
        fieldName = 'name';
    }

    List<dynamic> imageUrls = data['imageUrls'] ?? [];
    String firstImageUrl = imageUrls.isNotEmpty ? imageUrls[0] : '';

    return ServiceModel(
      id: doc.id,
      name: data[fieldName] ?? '',
      imageUrl: firstImageUrl,
    );
  }
}
