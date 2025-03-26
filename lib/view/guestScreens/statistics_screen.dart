import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:guest_hotel/model/app_constants.dart';
import 'package:guest_hotel/model/booking_model.dart';
import 'package:guest_hotel/model/posting_model.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

class StatisticScreen extends StatefulWidget {
  const StatisticScreen({super.key});

  @override
  State<StatisticScreen> createState() => _StatisticScreenState();
}

class _StatisticScreenState extends State<StatisticScreen> {
  int postingCount = 0;
  int bookingCount = 0;
  List<BookingModel> allBookings =
      []; // Thêm danh sách để lưu thông tin đặt phòng

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    var userModel = AppConstants.currentUser;

    // Lấy danh sách bài đăng
    List<PostingModel> postings = await userModel.getPostings();
    List<BookingModel> bookings = await userModel.getBookings();

    // Lấy danh sách đặt phòng cho từng bài đăng
    for (var posting in postings) {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('postings')
          .doc(posting.id)
          .collection('bookings')
          .get();

      for (var doc in snapshot.docs) {
        BookingModel booking = BookingModel();
        await booking.getBookingInfoFromFirestoreFromPosting(posting, doc);
        bookings.add(booking);
      }
    }

    setState(() {
      postingCount = postings.length;
      bookingCount = bookings.length;
      allBookings = bookings; // Lưu thông tin đặt phòng vào danh sách
    });
  }

  Future<List<Map<String, dynamic>>> _fetchUserBookings() async {
    String currentUserID = AppConstants.currentUser.id ?? '';

    // Truy vấn danh sách bài đăng của người dùng hiện tại
    QuerySnapshot postingSnapshot = await FirebaseFirestore.instance
        .collection('postings')
        .where('hostID', isEqualTo: currentUserID)
        .get();

    List<String> postingIDs =
        postingSnapshot.docs.map((doc) => doc.id).toList();

    // Truy vấn danh sách đặt phòng liên quan đến các bài đăng
    QuerySnapshot bookingSnapshot = await FirebaseFirestore.instance
        .collection('bookings')
        .where('postingID', whereIn: postingIDs)
        .get();

    List<Map<String, dynamic>> bookings = bookingSnapshot.docs
        .map((doc) => doc.data() as Map<String, dynamic>)
        .toList();

    // Lấy thông tin chi tiết từng bài đăng
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
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Phần hiển thị thống kê tổng quan (Postings, Bookings)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildInfoCard(
                      postingCount.toString(), "Postings", Colors.purple),
                  _buildInfoCard(
                      bookingCount.toString(), "Bookings", Colors.blue),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildCircularIndicator(
                      "Booking", bookingCount / 100.0, Colors.blue),
                  _buildCircularIndicator(
                      "Posting", postingCount / 100.0, Colors.green),
                ],
              ),
              const SizedBox(height: 20),

              // Phần hiển thị danh sách thông tin đặt phòng
              const Text(
                "Booking Details",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: _fetchUserBookings(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return const Center(
                        child: Text('Error loading statistics.'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('No bookings found.'));
                  } else {
                    List<Map<String, dynamic>> bookings = snapshot.data!;
                    return ListView.builder(
                      shrinkWrap: true, // Đảm bảo không bị lỗi kích thước
                      physics: const NeverScrollableScrollPhysics(),
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
                              return const Center(
                                  child: CircularProgressIndicator());
                            } else if (imageSnapshot.hasError) {
                              return const Center(
                                  child: Text('Error loading image.'));
                            } else {
                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
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
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(String value, String label, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [color.withOpacity(0.7), color]),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: 10,
              spreadRadius: 5,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            const Icon(Icons.insert_chart, color: Colors.white, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(label,
                style: const TextStyle(color: Colors.white70, fontSize: 16)),
          ],
        ),
      ),
    );
  }

  Widget _buildCircularIndicator(String label, double percentage, Color color) {
    return Expanded(
      child: Column(
        children: [
          CircularPercentIndicator(
            radius: 50.0,
            lineWidth: 8.0,
            percent: percentage,
            center: Text(
              "${(percentage * 100).round()}%",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            progressColor: color,
            backgroundColor: Colors.grey[300]!,
          ),
          const SizedBox(height: 8),
          Text(label,
              style: const TextStyle(color: Colors.black54, fontSize: 14)),
        ],
      ),
    );
  }
}
