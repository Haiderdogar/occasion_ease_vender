import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:occasionease/home/home_screen.dart';

class ServicesSelection extends ConsumerWidget {
  const ServicesSelection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final services = [
      'Beauty Parlors',
      'Saloons',
      'Marriage Halls',
      'Farm Houses',
      'Catering',
      'Photographer'
    ];
    final selectedServices = ref.watch(servicesProvider);
    final isLoading = ref.watch(loadingProvider);

    return Scaffold(
      body: Container(
        color: Colors.white,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Select Your Services',
                  style: TextStyle(
                    color: Colors.blue.shade800,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: services.length,
                  itemBuilder: (context, index) {
                    final service = services[index];
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: selectedServices.contains(service)
                            ? Colors.blue.shade100
                            : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: CheckboxListTile(
                        title: Text(
                          service,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade800,
                          ),
                        ),
                        value: selectedServices.contains(service),
                        onChanged: (_) {
                          ref
                              .read(servicesProvider.notifier)
                              .toggleService(service);
                        },
                        activeColor: Colors.blue.shade800,
                        checkColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  onPressed:
                      isLoading ? null : () => _submitServices(context, ref),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.blue.shade800,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.0,
                          ),
                        )
                      : const Text(
                          'Submit',
                          style: TextStyle(fontSize: 18),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitServices(BuildContext context, WidgetRef ref) async {
    final selectedServices =
        ref.read(servicesProvider); // List of selected services
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      try {
        ref.read(loadingProvider.notifier).state = true;

        final vendorsCollection =
            FirebaseFirestore.instance.collection('vendors');
        final userDoc = vendorsCollection.doc(user.uid);

        // Update loginsuccess and selected services
        await userDoc.set({
          'loginsuccess': true,
          'selectedServices': selectedServices,
        }, SetOptions(merge: true));

        // Success feedback
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Services submitted successfully'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate to the HomeScreen
        Navigator.pushAndRemoveUntil(
          // ignore: use_build_context_synchronously
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (route) => false,
        );
      } catch (e) {
        // Error feedback
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting services: $e'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        ref.read(loadingProvider.notifier).state = false;
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User not logged in'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

final servicesProvider =
    StateNotifierProvider<ServicesNotifier, List<String>>((ref) {
  return ServicesNotifier();
});

class ServicesNotifier extends StateNotifier<List<String>> {
  ServicesNotifier() : super([]);

  void toggleService(String service) {
    if (state.contains(service)) {
      state = state.where((s) => s != service).toList();
    } else {
      state = [...state, service];
    }
  }
}

final loadingProvider = StateProvider<bool>((ref) => false);
