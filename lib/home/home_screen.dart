import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:occasionease/home/bookimg_screen.dart';
import 'package:occasionease/home/profile';
import 'package:occasionease/login/login_screen.dart';
import 'package:occasionease/view_all_services/view.dart';

final servicesProvider = FutureProvider<List<String>>((ref) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) throw Exception('User not logged in');

  final userDoc = await FirebaseFirestore.instance
      .collection('newVendors')
      .doc(user.uid)
      .get();

  return List<String>.from(userDoc.data()?['selectedServices'] ?? []);
});

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final servicesAsyncValue = ref.watch(servicesProvider);

    return Scaffold(
      appBar: AppBar(
        title:
            const Text('Occasion Ease', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue.shade800,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer: _buildDrawer(context),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue.shade50, Colors.blue.shade100],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Selected Services',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade800,
                        ),
                      ),
                      const SizedBox(height: 24),
                      GestureDetector(
                        onTap: () => _handleAddService(context, ref),
                        child: Container(
                          width: double.infinity, // Full width button
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Colors.blue,
                                Colors.blue,
                              ], // Elegant blue-purple gradient
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius:
                                BorderRadius.circular(15), // Pill-shaped button
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.5),
                                blurRadius: 12,
                                spreadRadius: 0,
                                offset: const Offset(0, 6), // Subtle elevation
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.add_circle,
                                size: 24,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Add New Service',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                  letterSpacing: 0.7,
                                  shadows: [
                                    Shadow(
                                      blurRadius: 3,
                                      color: Colors.black.withOpacity(0.3),
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Expanded(
                        child: servicesAsyncValue.when(
                          data: (services) => services.isEmpty
                              ? _buildNoServices()
                              : _buildServicesGrid(context, ref, services),
                          loading: () =>
                              const Center(child: CircularProgressIndicator()),
                          error: (error, stack) => _buildErrorWidget(error),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleAddService(BuildContext context, WidgetRef ref) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userDoc = await FirebaseFirestore.instance
        .collection('newVendors')
        .doc(user.uid)
        .get();
    final selectedServices =
        List<String>.from(userDoc.data()?['selectedServices'] ?? []);

    const allServices = [
      'Saloons',
      'Farm Houses',
      'Catering',
      'Beauty Parlors',
      'Marriage Halls',
      'Photographer'
    ];

    final availableServices = allServices
        .where((service) => !selectedServices.contains(service))
        .toList();

    if (availableServices.isEmpty) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Already all services selected')),
      );
    } else {
      // ignore: use_build_context_synchronously
      _showAddServiceDialog(context, ref, availableServices);
    }
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Colors.blue.shade800),
            child: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('newVendors')
                  .doc(FirebaseAuth.instance.currentUser?.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                final profileImage = snapshot.data?['profileImage'] as String?;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white,
                      backgroundImage: profileImage != null
                          ? NetworkImage(profileImage)
                          : null,
                      child: profileImage == null
                          ? const Icon(Icons.person,
                              color: Colors.blue, size: 30)
                          : null,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      FirebaseAuth.instance.currentUser?.email ?? 'User',
                      style: const TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ],
                );
              },
            ),
          ),
          ListTile(
            leading: const Icon(Icons.event, color: Colors.blue),
            title: const Text('Booking Order', style: TextStyle(fontSize: 16)),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const BookingOrderScreen()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.person, color: Colors.blue),
            title: const Text('Profile', style: TextStyle(fontSize: 16)),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfileScreen()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(fontSize: 16)),
            onTap: () => _logout(context),
          ),
        ],
      ),
    );
  }

  Widget _buildNoServices() {
    return Center(
      child: Text(
        'No services available',
        style: TextStyle(
          fontSize: 18,
          color: Colors.blue.shade600,
        ),
      ),
    );
  }

  Widget _buildServicesGrid(
      BuildContext context, WidgetRef ref, List<String> services) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: services.length,
      itemBuilder: (context, index) =>
          _buildServiceCard(context, ref, services[index]),
    );
  }

  Widget _buildErrorWidget(Object error) {
    return Center(
      child: Text(
        'Error: ${error.toString()}',
        style: TextStyle(color: Colors.red.shade800),
      ),
    );
  }

  Future<void> _showAddServiceDialog(BuildContext context, WidgetRef ref,
      List<String> availableServices) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20), // Smoother rounded corners
        ),
        title: const Row(
          children: [
            Icon(Icons.design_services,
                color: Colors.blueAccent), // Custom icon
            SizedBox(width: 8),
            Text(
              'Choose a Service',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent, // Matching theme color
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: availableServices.length,
            itemBuilder: (context, index) => Card(
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              color: Colors.blue.shade50, // Soft blue background for contrast
              elevation: 3,
              child: ListTile(
                title: Text(
                  availableServices[index],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.blueAccent, // Themed text color
                  ),
                ),
                leading: const Icon(Icons.miscellaneous_services,
                    color: Colors.blueAccent),
                trailing: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 18),
                ),
                onTap: () =>
                    _confirmAddService(context, ref, availableServices[index]),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmAddService(
      BuildContext context, WidgetRef ref, String service) async {
    Navigator.pop(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Service'),
        content: Text('Are you sure you want to add $service?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await FirebaseFirestore.instance
          .collection('newVendors')
          .doc(user.uid)
          .update({
        'selectedServices': FieldValue.arrayUnion([service])
      });

      ref.invalidate(servicesProvider);
    }
  }

  Widget _buildServiceCard(
      BuildContext context, WidgetRef ref, String serviceName) {
    return Stack(
      children: [
        Card(
          elevation: 4,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: InkWell(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) =>
                      ServicesViewScreen(serviceName: serviceName)),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.blue.shade400, Colors.blue.shade600],
                ),
              ),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    serviceName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          right: 8,
          top: 8,
          child: PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'delete',
                child: Text('Delete'),
              ),
            ],
            onSelected: (value) =>
                _handleServiceAction(context, ref, value, serviceName),
          ),
        ),
      ],
    );
  }

  Future<void> _handleServiceAction(BuildContext context, WidgetRef ref,
      String action, String serviceName) async {
    if (action == 'delete') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete Service'),
          content: const Text(
              'All data related to this service will be deleted. Confirm?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) return;

        // Delete from service collection
        final querySnapshot = await FirebaseFirestore.instance
            .collection(serviceName)
            .where('userId', isEqualTo: user.uid)
            .get();

        final batch = FirebaseFirestore.instance.batch();
        for (final doc in querySnapshot.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();

        // Remove from selected services
        await FirebaseFirestore.instance
            .collection('newVendors')
            .doc(user.uid)
            .update({
          'selectedServices': FieldValue.arrayRemove([serviceName])
        });

        ref.invalidate(servicesProvider);
      }
    }
  }

  void _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    // ignore: use_build_context_synchronously
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (Route<dynamic> route) => false,
    );
  }
}
