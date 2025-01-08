import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:occasionease/data_upload/beauty_polor/beautypoloar.dart';
import 'package:occasionease/data_upload/catering/catering.dart';
import 'package:occasionease/data_upload/mariage_hall/hall_data_upload.dart';
import 'package:occasionease/data_upload/photographer/photographer.dart';
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

  Future<List<ServiceModel>> _fetchServices(
      String serviceName, String userId) async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection(serviceName)
        .where('userId', isEqualTo: userId)
        .get();

    return snapshot.docs
        .map((doc) => ServiceModel.fromFirestore(doc, serviceName))
        .toList();
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
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue[700]!, Colors.blue[100]!],
          ),
        ),
        child: FutureBuilder<List<ServiceModel>>(
          future: _fetchServices(serviceName, userId),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                  child: Text('Error: ${snapshot.error}',
                      style: TextStyle(color: Colors.white)));
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                  child: CircularProgressIndicator(color: Colors.white));
            }

            final services = snapshot.data ?? [];

            if (services.isEmpty) {
              return Center(
                  child: Text('No services found.',
                      style: TextStyle(color: Colors.white)));
            }

            return ListView.builder(
              itemCount: services.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: Stack(
                        children: [
                          Image.network(
                            services[index].imageUrl,
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withOpacity(0.7)
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 16,
                            left: 16,
                            right: 16,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  services[index].name,
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold),
                                ),
                                SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    ElevatedButton(
                                      onPressed: () {
                                        // Handle Edit action
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue[300],
                                      ),
                                      child: Text('Edit'),
                                    ),
                                    FutureBuilder<bool>(
                                      future: _checkIfPromotionExists(
                                          serviceName, services[index].id),
                                      builder: (context, promoSnapshot) {
                                        if (promoSnapshot.connectionState ==
                                            ConnectionState.waiting) {
                                          return CircularProgressIndicator(
                                              color: Colors.white);
                                        }
                                        final isPromoted =
                                            promoSnapshot.data ?? false;
                                        return ElevatedButton(
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
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: isPromoted
                                                ? Colors.grey
                                                : Colors.green,
                                          ),
                                          child: Text(isPromoted
                                              ? 'Promoted'
                                              : 'Promote'),
                                        );
                                      },
                                    ),
                                    ElevatedButton(
                                      onPressed: () async {
                                        await _deleteService(
                                            serviceName, services[index].id);
                                        // Refresh the screen after deletion
                                        (context as Element).markNeedsBuild();
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                      ),
                                      child: Text('Delete'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToNextScreen(context, serviceName),
        tooltip: 'Add $serviceName',
        child: const Icon(Icons.add),
        backgroundColor: Colors.blue[700],
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
