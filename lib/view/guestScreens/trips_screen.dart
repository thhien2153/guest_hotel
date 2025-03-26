import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:guest_hotel/model/app_constants.dart';
import 'package:intl/intl.dart'; // Import package intl

class TripsScreen extends StatefulWidget {
  const TripsScreen({super.key});

  @override
  State<TripsScreen> createState() => _TripsScreenState();
}

class _TripsScreenState extends State<TripsScreen> {
  Future<List<Map<String, dynamic>>> _fetchUserBookings() async {
    String currentUserID = AppConstants.currentUser.id ?? '';
    QuerySnapshot bookingSnapshot = await FirebaseFirestore.instance
        .collection('bookings')
        .where('userID', isEqualTo: currentUserID)
        .get();

    List<Map<String, dynamic>> bookings = bookingSnapshot.docs
        .map((doc) => doc.data() as Map<String, dynamic>)
        .toList();

    for (var booking in bookings) {
      DocumentSnapshot postingSnapshot = await FirebaseFirestore.instance
          .collection('postings')
          .doc(booking['postingID'])
          .get();

      booking['posting'] = postingSnapshot.data();
    }

    return bookings;
  }

  Future<String> _getImageUrl(String postingID, String imageName) async {
    Reference ref = FirebaseStorage.instance
        .ref()
        .child('postingImages')
        .child(postingID)
        .child(imageName);
    return await ref.getDownloadURL();
  }

  String _formatDate(dynamic date) {
    if (date is Timestamp) {
      DateTime dateTime = date.toDate();
      return DateFormat('dd/MM/yyyy').format(dateTime);
    } else if (date is String) {
      try {
        DateTime dateTime = DateTime.parse(date);
        return DateFormat('dd/MM/yyyy').format(dateTime);
      } catch (e) {
        return date;
      }
    } else {
      return 'Invalid date';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchUserBookings(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(child: Text('Error loading bookings.'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No bookings found.'));
          } else {
            List<Map<String, dynamic>> bookings = snapshot.data!;
            return ListView.builder(
              itemCount: bookings.length,
              itemBuilder: (context, index) {
                var booking = bookings[index];
                var posting = booking['posting'];

                return FutureBuilder<String>(
                  future: _getImageUrl(
                    booking['postingID'],
                    posting['imageNames'].first,
                  ),
                  builder: (context, imageSnapshot) {
                    if (imageSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (imageSnapshot.hasError) {
                      return const Center(child: Text('Error loading image.'));
                    } else {
                      return Card(
                        margin: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Hình ảnh lớn hơn
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.network(
                                imageSnapshot.data!,
                                width: double.infinity,
                                height: 200,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    posting['name'] ?? 'No Name',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                      'Price: \ ${posting['price'] ?? 'N/A'}/night'),
                                  Text(
                                      'Booked by: ${booking['name'] ?? 'No Name'}'),
                                  Text(
                                      'Email: ${booking['email'] ?? 'No Email'}'),
                                  Text(
                                      'Phone: ${booking['phone'] ?? 'No Phone'}'),
                                  Text(
                                      'Check-in: ${_formatDate(booking['dates'].first)}'),
                                  Text(
                                      'Check-out: ${_formatDate(booking['dates'].last)}'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                  },
                );
              },
            );
          }
        },
      ),
    );
  }
}
