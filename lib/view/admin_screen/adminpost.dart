import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:guest_hotel/view/admin_screen/adminpostreport.dart';

class AdminPost extends StatefulWidget {
  const AdminPost({super.key});

  @override
  State<AdminPost> createState() => _AdminPostState();
}

class _AdminPostState extends State<AdminPost> {
  final Map<String, String> _imageCache = {}; // Cache for image URLs
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Method to get the image URL from Firebase Storage
  Future<String> _getImageUrl(String postingId, String imageName) async {
    if (_imageCache.containsKey(imageName)) {
      return _imageCache[imageName]!;
    }

    final ref = FirebaseStorage.instance
        .ref()
        .child("postingImages")
        .child(postingId)
        .child(imageName);
    final url = await ref.getDownloadURL();

    _imageCache[imageName] = url;
    return url;
  }

  // Method to delete a post from Firestore
  Future<void> _deletePost(String postId) async {
    try {
      await FirebaseFirestore.instance
          .collection('postings')
          .doc(postId)
          .delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Post deleted successfully")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error deleting post: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Posts"),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: const Icon(Icons.report, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const AdminPostReport()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              onChanged: (query) {
                setState(() {
                  _searchQuery = query.toLowerCase();
                });
              },
              decoration: const InputDecoration(
                labelText: "Search by address",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          // Post Stream
          Expanded(
            child: StreamBuilder(
              stream:
                  FirebaseFirestore.instance.collection("postings").snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No posts available"));
                }

                // Filter posts based on the search query
                var filteredPosts = snapshot.data!.docs.where((post) {
                  var address = post['address'] ?? '';
                  return address.toLowerCase().contains(_searchQuery);
                }).toList();

                return ListView.builder(
                  itemCount: filteredPosts.length,
                  itemBuilder: (context, index) {
                    var posting = filteredPosts[index];
                    var postingId = posting.id;
                    var imageNames =
                        List<String>.from(posting['imageNames'] ?? []);
                    var postName = posting['name'] ?? "No Title";
                    var postPrice = posting['price'] ?? 0.0;
                    var postRating = posting['rating'] ?? 3.5;
                    var postAddress = posting['address'] ?? "No Address";
                    var postCity = posting['city'] ?? "No City";
                    var postCountry = posting['country'] ?? "No Country";
                    var postType = posting['type'] ?? "No Type";
                    var postDescription =
                        posting['description'] ?? "No Description";
                    var postAmenities = posting['amenities'] ?? "No Amenities";
                    var postBathrooms = posting['bathrooms'] ?? "N/A";
                    var postBeds = posting['beds'] ?? "N/A";

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Post Image
                            imageNames.isNotEmpty
                                ? FutureBuilder(
                                    future:
                                        _getImageUrl(postingId, imageNames[0]),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return Container(
                                          color: Colors.grey[300],
                                          child: const Center(
                                            child: CircularProgressIndicator(),
                                          ),
                                        );
                                      }
                                      if (snapshot.hasError) {
                                        return Container(
                                          color: Colors.grey[300],
                                          child: const Center(
                                            child: Icon(Icons.broken_image,
                                                size: 40, color: Colors.red),
                                          ),
                                        );
                                      }
                                      return Image.network(
                                        snapshot.data!,
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        height: 200,
                                      );
                                    },
                                  )
                                : Container(
                                    height: 200,
                                    color: Colors.grey[300],
                                    child: const Center(
                                      child: Icon(Icons.image, size: 40),
                                    ),
                                  ),
                            const SizedBox(height: 8),
                            // Post Title
                            Text(
                              postName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                            const SizedBox(height: 4),
                            // Post Details (Price, Rating, Address)
                            Text(
                              "$postPrice VND",
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.red,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.star,
                                    color: Colors.orange, size: 18),
                                const SizedBox(width: 4),
                                Text("$postRating"),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Address: $postAddress, $postCity, $postCountry",
                              style: const TextStyle(
                                  fontSize: 14, color: Colors.black54),
                            ),
                            const SizedBox(height: 8),
                            // Additional Info (Description, Amenities, Bathrooms, Beds)
                            Text(
                              "Description: $postDescription",
                              style: const TextStyle(
                                  fontSize: 14, color: Colors.black54),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Amenities: $postAmenities",
                              style: const TextStyle(
                                  fontSize: 14, color: Colors.black54),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Bathrooms: $postBathrooms",
                              style: const TextStyle(
                                  fontSize: 14, color: Colors.black54),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Beds: $postBeds",
                              style: const TextStyle(
                                  fontSize: 14, color: Colors.black54),
                            ),
                            const SizedBox(height: 8),
                            // Delete Button
                            Align(
                              alignment: Alignment.centerRight,
                              child: ElevatedButton(
                                onPressed: () {
                                  _deletePost(postingId);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: const Text("Delete Post"),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
