import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BookingOrderScreen extends ConsumerWidget {
  const BookingOrderScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('No user logged in'));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bookings', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue.shade800,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue.shade50, Colors.blue.shade100],
          ),
        ),
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _fetchBookings(user.uid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error: ${snapshot.error}',
                  style: TextStyle(color: Colors.red.shade800),
                ),
              );
            }

            final bookings = snapshot.data ?? [];
            if (bookings.isEmpty) {
              return Center(
                child: Text(
                  'No bookings found',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.blue.shade600,
                  ),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: bookings.length,
              itemBuilder: (context, index) {
                final booking = bookings[index];
                return _buildBookingCard(booking);
              },
            );
          },
        ),
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _fetchBookings(String userId) async {
    final bookings = <Map<String, dynamic>>[];
    final collections = [
      {
        'name': 'BeautyParlorBookings',
        'type': 'Beauty Parlor',
        'itemsKey': 'services'
      },
      {'name': 'CateringBookings', 'type': 'Catering', 'itemsKey': 'services'},
      {'name': 'FarmBookings', 'type': 'Farmhouse', 'itemsKey': 'rooms'},
      {
        'name': 'MarriageHallBookings',
        'type': 'Marriage Hall',
        'itemsKey': 'services'
      },
      {
        'name': 'PhotographerBookings',
        'type': 'Photographer',
        'itemsKey': 'services'
      },
      {'name': 'SaloonBookings', 'type': 'Saloon', 'itemsKey': 'services'},
    ];

    for (var collection in collections) {
      final snapshot = await FirebaseFirestore.instance
          .collection(collection['name'] as String)
          .where('userId', isEqualTo: userId)
          .get();

      for (var doc in snapshot.docs) {
        final data = doc.data();
        data['type'] = collection['type'];
        data['itemsKey'] = collection['itemsKey'];
        bookings.add(data);
      }
    }

    // Sort bookings by date (newest first)
    bookings.sort((a, b) => (b['date'] ?? '').compareTo(a['date'] ?? ''));
    return bookings;
  }

  Widget _buildBookingCard(Map<String, dynamic> booking) {
    final itemsKey = booking['itemsKey'] as String? ?? 'services';
    final items = List<Map<String, dynamic>>.from(booking[itemsKey] ?? []);
    final status = booking['status'] as String? ?? 'Pending';
    final type = booking['type'] as String? ?? 'Booking';
    final date = booking['date'] as String? ?? 'No date specified';
    final timeSlot = booking['timeSlot'] as String?;

    // Calculate total price
    double totalPrice = (booking['totalPrice'] as num?)?.toDouble() ?? 0.0;
    if (totalPrice == 0) {
      for (var item in items) {
        totalPrice += (item['price'] as num).toDouble() *
            (item['quantity'] as num).toDouble();
      }
    }

    // Status color coding
    final statusColor = _getStatusColor(status);
    final formattedDate = _formatDate(date);

    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    type,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade900,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor, width: 1),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.calendar_today, formattedDate),
            if (timeSlot != null) _buildInfoRow(Icons.access_time, timeSlot),
            const Divider(height: 30),
            Text(
              'BOOKED ITEMS',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            ...items.map((item) => _buildItemRow(item)),
            const Divider(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Price:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                Text(
                  '\$${totalPrice.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade900,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemRow(Map<String, dynamic> item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              item['name'] ?? 'Unnamed Service',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade800,
              ),
            ),
          ),
          Text(
            '${item['quantity']} x \$${item['price']}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Colors.green;
      case 'completed':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      default: // Pending
        return Colors.orange;
    }
  }

  String _formatDate(String date) {
    try {
      final parsedDate = DateTime.parse(date);
      return "${parsedDate.day}/${parsedDate.month}/${parsedDate.year}";
    } catch (e) {
      return date;
    }
  }
}
