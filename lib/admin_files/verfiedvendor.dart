import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class VerifiedVendorsScreen extends StatefulWidget {
  const VerifiedVendorsScreen({Key? key}) : super(key: key);

  @override
  _VerifiedVendorsScreenState createState() => _VerifiedVendorsScreenState();
}

class _VerifiedVendorsScreenState extends State<VerifiedVendorsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verified Vendors'),
        backgroundColor: Colors.green[800],
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.green[800]!, Colors.green[400]!],
          ),
        ),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('newVendors')
              .where('isVerified', isEqualTo: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                  child: CircularProgressIndicator(color: Colors.white));
            }

            if (snapshot.hasError) {
              return Center(
                  child: Text('Error: ${snapshot.error}',
                      style: const TextStyle(color: Colors.white)));
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(
                  child: Text('No verified vendors.',
                      style: TextStyle(color: Colors.white)));
            }

            return ListView.builder(
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                var vendorData =
                    snapshot.data!.docs[index].data() as Map<String, dynamic>;
                var vendorId = snapshot.data!.docs[index].id;

                return VendorCard(
                  vendorData: vendorData,
                  vendorId: vendorId,
                  onBlockStatusChanged: () {
                    // This will force a rebuild of the widget
                    setState(() {});
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class VendorCard extends StatefulWidget {
  final Map<String, dynamic> vendorData;
  final String vendorId;
  final VoidCallback onBlockStatusChanged;

  const VendorCard({
    Key? key,
    required this.vendorData,
    required this.vendorId,
    required this.onBlockStatusChanged,
  }) : super(key: key);

  @override
  _VendorCardState createState() => _VendorCardState();
}

class _VendorCardState extends State<VendorCard> {
  late bool isBlocked;

  @override
  void initState() {
    super.initState();
    isBlocked = widget.vendorData['isBlocked'] ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.vendorData['username'],
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.vendorData['email'],
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: !isBlocked,
                  onChanged: (value) => _toggleBlockStatus(!value),
                  activeColor: Colors.green,
                  inactiveThumbColor: Colors.red,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'CNIC Images:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (var imageUrl in widget.vendorData['cnicImages'])
                  GestureDetector(
                    onTap: () => _showImageDialog(context, imageUrl),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image(
                        image: NetworkImage(imageUrl),
                        width: 120,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 120,
                            height: 80,
                            color: Colors.grey[300],
                            child: const Icon(Icons.error),
                          );
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            width: 120,
                            height: 80,
                            color: Colors.grey[200],
                            child: Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes !=
                                        null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton(
                onPressed: () => _toggleBlockStatus(!isBlocked),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isBlocked ? Colors.green : Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                child: Text(
                  isBlocked ? 'Unblock Vendor' : 'Block Vendor',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleBlockStatus(bool newBlockedStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('newVendors')
          .doc(widget.vendorId)
          .update({
        'isBlocked': newBlockedStatus,
      });

      setState(() {
        isBlocked = newBlockedStatus;
      });

      widget.onBlockStatusChanged();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Vendor ${newBlockedStatus ? 'blocked' : 'unblocked'} successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating vendor status: $e')),
      );
    }
  }

  void _showImageDialog(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Container(
            width: double.infinity,
            height: 400,
            decoration: BoxDecoration(
              color: Colors.grey[200],
            ),
            child: Image(
              image: NetworkImage(imageUrl),
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return const Center(
                  child: Text('Failed to load image'),
                );
              },
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
