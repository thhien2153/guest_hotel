import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminUser extends StatefulWidget {
  const AdminUser({super.key});

  @override
  State<AdminUser> createState() => _AdminUserState();
}

class _AdminUserState extends State<AdminUser> {
  String searchQuery = "";

  Future<void> _deleteUser(String userId, String email) async {
    try {
      // Xóa tất cả các bài đăng có hostID = userId
      final postingsQuery = await FirebaseFirestore.instance
          .collection('postings')
          .where('hostID', isEqualTo: userId)
          .get();

      for (var doc in postingsQuery.docs) {
        await doc.reference.delete();
      }

      // Xóa người dùng khỏi Firestore
      await FirebaseFirestore.instance.collection('users').doc(userId).delete();

      // Xóa người dùng khỏi Firebase Authentication
      List<String> signInMethods =
          await FirebaseAuth.instance.fetchSignInMethodsForEmail(email);

      if (signInMethods.isNotEmpty) {
        final user = await FirebaseAuth.instance.currentUser;
        if (user != null) {
          await user.delete();
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('User and related data deleted successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting user: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin - Manage Users'),
        backgroundColor: Colors.green,
      ),
      body: Column(
        children: [
          // Thanh tìm kiếm
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by email...',
                prefixIcon: const Icon(Icons.search, color: Colors.green),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.green),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.green),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          Expanded(
            // StreamBuilder để cập nhật thời gian thực
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where('role', isEqualTo: 'user')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No users found.'));
                }

                // Lọc người dùng theo từ khóa tìm kiếm
                final filteredUsers = snapshot.data!.docs.where((doc) {
                  final email = doc['email']?.toString()?.toLowerCase() ?? '';
                  return email.contains(searchQuery);
                }).toList();

                if (filteredUsers.isEmpty) {
                  return const Center(child: Text('No matching users found.'));
                }

                return ListView.builder(
                  itemCount: filteredUsers.length,
                  itemBuilder: (context, index) {
                    final user = filteredUsers[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 10.0, vertical: 8.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15.0),
                      ),
                      elevation: 5,
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Icon hình người
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: Colors.green[300],
                              child: const Icon(
                                Icons.person,
                                size: 30,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 10),
                            // Thông tin chi tiết
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${user['firstName']} ${user['lastName']}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text('Email: ${user['email']}'),
                                  Text('Bio: ${user['bio'] ?? 'N/A'}'),
                                  Text('City: ${user['city'] ?? 'N/A'}'),
                                  Text('Country: ${user['country'] ?? 'N/A'}'),
                                  Text('Earnings: \$${user['earnings'] ?? 0}'),
                                ],
                              ),
                            ),
                            // Nút xóa
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Delete User'),
                                    content: const Text(
                                        'Are you sure you want to delete this user and their associated data?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(false),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(true),
                                        child: const Text('Delete'),
                                      ),
                                    ],
                                  ),
                                );

                                if (confirm == true) {
                                  await _deleteUser(user.id, user['email']);
                                }
                              },
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
