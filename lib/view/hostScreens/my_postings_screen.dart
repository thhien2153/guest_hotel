import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:guest_hotel/model/app_constants.dart';
import 'package:guest_hotel/model/posting_model.dart';
import 'package:guest_hotel/view/hostScreens/create_posting_screen.dart';
import 'package:guest_hotel/view/widgets/posting_list_tile_button.dart';
import 'package:guest_hotel/view/widgets/posting_list_tile_ui.dart';

class MyPostingsScreen extends StatefulWidget {
  const MyPostingsScreen({super.key});

  @override
  State<MyPostingsScreen> createState() => _MyPostingsScreenState();
}

class _MyPostingsScreenState extends State<MyPostingsScreen> {
  List<PostingModel> userPostings = [];

  @override
  void initState() {
    super.initState();
    _filterUserPostings();
  }

  void _filterUserPostings() {
    final currentUserID = AppConstants.currentUser.id;
    userPostings = AppConstants.currentUser.myPostings!
        .where((posting) => posting.host!.id == currentUserID)
        .toList();
    setState(() {});
  }

  Future<void> _deletePosting(PostingModel posting) async {
    try {
      await FirebaseFirestore.instance
          .collection('postings')
          .doc(posting.id)
          .delete();
      setState(() {
        userPostings.remove(posting);
      });
      Get.snackbar("Success", "Posting deleted successfully.");
    } catch (e) {
      Get.snackbar("Error", "Failed to delete posting.");
    }
  }

  void _showDeleteConfirmationDialog(PostingModel posting) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Delete Posting"),
          content: Text("Are you sure you want to delete this post?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("No"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deletePosting(posting);
              },
              child: Text("Delete"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 25),
      child: ListView.builder(
        itemCount: userPostings.length + 1,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: InkResponse(
              onTap: () {
                if (index == userPostings.length) {
                  Get.to(CreatePostingScreen(posting: null));
                } else {
                  Get.to(CreatePostingScreen(posting: userPostings[index]));
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.green,
                    width: 1.2,
                  ),
                ),
                child: (index == userPostings.length)
                    ? const PostingListTileButton()
                    : Stack(
                        children: [
                          PostingListTileUI(
                            posting: userPostings[index],
                          ),
                          Positioned(
                            top: 0,
                            right: 0,
                            child: IconButton(
                              icon: Icon(Icons.close, color: Colors.red),
                              onPressed: () => _showDeleteConfirmationDialog(
                                  userPostings[index]),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          );
        },
      ),
    );
  }
}
