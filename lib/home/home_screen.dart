import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:occasionease/data_upload/beauty_polor/beautypoloar.dart';
import 'package:occasionease/data_upload/catering/catering.dart';
import 'package:occasionease/data_upload/mariage_hall/hall_data_upload.dart';
import 'package:occasionease/data_upload/photographer/photographer.dart';
import 'package:occasionease/login/login_screen.dart';

// FutureProvider to fetch selected services from Firestore
final servicesProvider = FutureProvider<List<String>>((ref) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) throw Exception('User not logged in');

  final userDoc = await FirebaseFirestore.instance
      .collection('vendors')
      .doc(user.uid)
      .get();

  if (userDoc.exists) {
    final selectedServices =
        List<String>.from(userDoc.data()?['selectedServices'] ?? []);
    return selectedServices;
  } else {
    return [];
  }
});

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Selected Services',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final User? user = FirebaseAuth.instance.currentUser;
    final servicesAsyncValue = ref.watch(servicesProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text(
          user?.email ?? 'User',
          style: const TextStyle(color: Colors.black87, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black87),
            onPressed: () => _showLogoutDialog(context),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Selected Services',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: servicesAsyncValue.when(
                  data: (services) => services.isEmpty
                      ? const Center(child: Text('No services available'))
                      : GridView.builder(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 1.3,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                          itemCount: services.length,
                          itemBuilder: (context, index) {
                            final serviceName = services[index];
                            return _buildButton(context, serviceName);
                          },
                        ),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => Center(
                    child: Text('Error: ${error.toString()}'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildButton(BuildContext context, String label) {
    return GestureDetector(
      onTap: () => _navigateToNextScreen(context, label),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.blue.shade800,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.shade200,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  void _navigateToNextScreen(BuildContext context, String serviceName) {
    if (serviceName == 'Beauty Parlors' || serviceName == 'Saloons') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BeautyParlorForm(serviceName: serviceName),
        ),
      );
    } else if (serviceName == 'Marriage Halls' ||
        serviceName == 'Farm Houses') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AddMarriageHallScreen(serviceName: serviceName),
        ),
      );
    } else if (serviceName == 'Photographer') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PhotographerServicesForm(),
        ),
      );
    } else if (serviceName == 'Catering') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CateringServicesForm(),
        ),
      );
    }
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Logout'),
              onPressed: () {
                _logout(context);
              },
            ),
          ],
        );
      },
    );
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
