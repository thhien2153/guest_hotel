import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _controller = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ScrollController _scrollController = ScrollController();

  Future<void> sendMessage(String message) async {
    if (message.trim().isEmpty) return;

    String userID = FirebaseAuth.instance.currentUser?.uid ?? '';

    if (userID.isEmpty) return; // Nếu chưa đăng nhập, không gửi tin nhắn

    // 🔹 Lưu tin nhắn vào subcollection 'messages' của user
    CollectionReference messagesRef = _firestore
        .collection('chatbot_messages')
        .doc(userID)
        .collection('messages');

    await messagesRef.add({
      'role': 'user',
      'text': message,
      'timestamp': FieldValue.serverTimestamp(),
    });

    setState(() {
      _controller.clear();
    });

    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    String userID = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              // 🔹 Lấy tất cả tin nhắn của user từ subcollection "messages"
              stream: _firestore
                  .collection('chatbot_messages')
                  .doc(userID)
                  .collection('messages')
                  .orderBy('timestamp',
                      descending: false) // Sắp xếp theo thời gian gửi
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("Chưa có tin nhắn nào"));
                }

                var messages = snapshot.data!.docs;

                return ListView.builder(
                  controller: _scrollController,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    var messageData =
                        messages[index].data() as Map<String, dynamic>;

                    return Align(
                      alignment: messageData['role'] == 'user'
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                            vertical: 5, horizontal: 10),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: messageData['role'] == 'user'
                              ? Colors.blue[200]
                              : Colors.green[200],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              messageData['text'],
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              DateFormat('HH:mm dd/MM/yyyy').format(
                                (messageData['timestamp'] as Timestamp?)
                                        ?.toDate() ??
                                    DateTime.now(),
                              ),
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey[700]),
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
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration:
                        const InputDecoration(hintText: "Nhập tin nhắn..."),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () {
                    sendMessage(_controller.text);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
