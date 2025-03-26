import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:typed_data';

class AdminPostReport extends StatefulWidget {
  const AdminPostReport({super.key});

  @override
  State<AdminPostReport> createState() => _AdminPostReportState();
}

class _AdminPostReportState extends State<AdminPostReport> {
  // Fetch reported posts from Firestore
  Future<List<Map<String, dynamic>>> fetchReportedPosts() async {
    List<Map<String, dynamic>> reportsData = [];

    QuerySnapshot reportsSnapshot =
        await FirebaseFirestore.instance.collection('postReports').get();

    for (var reportDoc in reportsSnapshot.docs) {
      var reportData = reportDoc.data() as Map<String, dynamic>;
      String postId = reportData['postId'];
      String userId = reportData['userId'];
      Timestamp timestamp = reportData['timestamp'];

      DocumentSnapshot postSnapshot = await FirebaseFirestore.instance
          .collection('postings')
          .doc(postId)
          .get();
      var postData = postSnapshot.exists
          ? postSnapshot.data() as Map<String, dynamic>
          : null;

      DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      var userData = userSnapshot.exists
          ? userSnapshot.data() as Map<String, dynamic>
          : null;

      reportsData.add({
        'reportId': reportDoc.id,
        'postId': postId,
        'post': postData,
        'user': userData,
        'timestamp': timestamp,
      });
    }
    return reportsData;
  }

  // Load the first image from Firebase Storage
  Future<Uint8List?> loadFirstImage(
      String postId, List<dynamic>? imageNames) async {
    if (imageNames == null || imageNames.isEmpty) return null;

    try {
      // Ensure we cast imageNames to List<String>
      List<String> imageNamesList = List<String>.from(imageNames);

      // Assuming the images are stored under "postingImages" in Firebase Storage.
      String imagePath = "postingImages/$postId/${imageNamesList[0]}";
      final imageRef = FirebaseStorage.instance.ref().child(imagePath);

      // Get the image as bytes
      final imageBytes =
          await imageRef.getData(1024 * 1024); // Limit size to 1MB
      return imageBytes;
    } catch (e) {
      print("Error loading image from Firebase Storage: $e");
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Reported Posts"),
        backgroundColor: Colors.green,
      ),
      body: FutureBuilder(
        future: fetchReportedPosts(),
        builder: (context, AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No reported posts available"));
          }

          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              var report = snapshot.data![index];
              var post = report['post'];
              var user = report['user'];
              var timestamp = report['timestamp'] as Timestamp;

              return Card(
                margin:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                elevation: 5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Post Image
                      FutureBuilder<Uint8List?>(
                        future: loadFirstImage(
                            report['postId'], post?['imageNames']),
                        builder:
                            (context, AsyncSnapshot<Uint8List?> imageSnapshot) {
                          if (imageSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }
                          if (imageSnapshot.hasData &&
                              imageSnapshot.data != null) {
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.memory(
                                imageSnapshot.data!,
                                height: 200,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            );
                          } else {
                            return Container(
                              height: 200,
                              width: double.infinity,
                              color: Colors.grey[300],
                              child: const Center(
                                child: Icon(Icons.image,
                                    size: 50, color: Colors.grey),
                              ),
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 8),

                      // Post Title
                      Text(
                        post?['name'] ?? 'Unknown Post',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Post Details
                      Text(
                        "Location: ${post?['address'] ?? ''}, ${post?['city'] ?? ''}, ${post?['country'] ?? ''}",
                        style: const TextStyle(
                            fontSize: 14, color: Colors.black87),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Price: ${post?['price'] ?? 0.0} VND",
                        style:
                            const TextStyle(fontSize: 14, color: Colors.green),
                      ),
                      const SizedBox(height: 8),

                      // Reporter and Timestamp
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              "Reported by: ${user?['email'] ?? 'Unknown Email'}",
                              style: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w500),
                            ),
                          ),
                          Text(
                            "Time: ${timestamp.toDate().toString().substring(0, 19)}",
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Action Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ElevatedButton(
                            onPressed: () async {
                              await FirebaseFirestore.instance
                                  .collection('postings')
                                  .doc(report['postId'])
                                  .delete();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text("Post deleted successfully")),
                              );
                              setState(() {}); // Refresh the list
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text("Delete Post"),
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              await FirebaseFirestore.instance
                                  .collection('postReports')
                                  .doc(report['reportId'])
                                  .delete();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text("Report deleted successfully")),
                              );
                              setState(() {}); // Refresh the list
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text("Delete Report"),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
