import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class PromotionBannerRequestsScreen extends StatefulWidget {
  const PromotionBannerRequestsScreen({Key? key}) : super(key: key);

  @override
  _PromotionBannerRequestsScreenState createState() =>
      _PromotionBannerRequestsScreenState();
}

class _PromotionBannerRequestsScreenState
    extends State<PromotionBannerRequestsScreen> {
  List<Map<String, dynamic>> _promotionBanners = [];

  @override
  void initState() {
    super.initState();
    _fetchPromotionBanners();
  }

  Future<void> _fetchPromotionBanners() async {
    try {
      var querySnapshot =
          await FirebaseFirestore.instance.collection('promotion_banner').get();

      List<Map<String, dynamic>> banners = [];
      for (var doc in querySnapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;

        // Fetch the first image URL from the related collection
        String? imageUrl =
            await _getFirstImageUrl(data['serviceName'], data['docId']);
        banners.add({
          'docId': data['docId'],
          'serviceName': data['serviceName'],
          'userId': data['userId'],
          'createdAt': data['createdAt'],
          'imageUrl': imageUrl,
        });
      }

      setState(() {
        _promotionBanners = banners;
      });
    } catch (e) {
      debugPrint('Error fetching promotion banners: $e');
    }
  }

  Future<String?> _getFirstImageUrl(String serviceName, String docId) async {
    try {
      var doc = await FirebaseFirestore.instance
          .collection(serviceName)
          .doc(docId)
          .get();

      if (!doc.exists) {
        return null;
      }

      var data = doc.data();
      if (data != null && data.containsKey('imageUrls')) {
        var imageUrls = data['imageUrls'];
        if (imageUrls is List && imageUrls.isNotEmpty) {
          return imageUrls[0]; // Return the first URL
        }
      }
    } catch (e) {
      debugPrint('Error fetching image URL: $e');
    }

    return null; // Return null if no valid URL is found
  }

  String _formatTimestamp(Timestamp timestamp) {
    var date = timestamp.toDate();
    return DateFormat('dd MMMM yyyy, HH:mm').format(date);
  }

  void _deletePromotion(String docId) async {
    try {
      var querySnapshot = await FirebaseFirestore.instance
          .collection('promotion_banner')
          .where('docId', isEqualTo: docId)
          .get();

      for (var doc in querySnapshot.docs) {
        await doc.reference.delete();
      }

      // Remove the deleted banner from the list
      setState(() {
        _promotionBanners.removeWhere((banner) => banner['docId'] == docId);
      });

      // Show success SnackBar
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Promotion deleted successfully!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
      debugPrint('Promotion deleted successfully');
    } catch (e) {
      debugPrint('Error deleting promotion: $e');

      // Show error SnackBar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting promotion: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Promotion Banner Requests'),
        backgroundColor: Colors.indigo,
      ),
      body: _promotionBanners.isEmpty
          ? const Center(
              child: Text(
                'No promotion banner requests found.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _promotionBanners.length,
              itemBuilder: (context, index) {
                var banner = _promotionBanners[index];
                return Card(
                  elevation: 6,
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLeadingImage(banner['imageUrl']),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    banner['serviceName'],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'User ID: ${banner['userId']}',
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Created At: ${_formatTimestamp(banner['createdAt'])}',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton.icon(
                            onPressed: () => _deletePromotion(banner['docId']),
                            icon: const Icon(Icons.delete),
                            label: const Text('Delete'),
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: Colors.red,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildLeadingImage(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Colors.grey[300],
        ),
        child: const Icon(Icons.image, size: 40, color: Colors.grey),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        imageUrl,
        width: 60,
        height: 60,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey[300],
            ),
            child: const Icon(Icons.error, size: 40, color: Colors.red),
          );
        },
      ),
    );
  }
}
