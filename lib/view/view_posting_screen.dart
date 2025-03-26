import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:guest_hotel/model/app_constants.dart';
import 'package:guest_hotel/model/posting_model.dart';
import 'package:guest_hotel/view/guestScreens/booking_listings_screen.dart';
import 'package:guest_hotel/view/widgets/posting_info_tile_ui.dart';

class PostingReport {
  final String userId;
  final String postId;

  PostingReport({required this.userId, required this.postId});

  Future<void> submitReport() async {
    try {
      await FirebaseFirestore.instance.collection('postReports').add({
        'userId': userId,
        'postId': postId,
        'timestamp': Timestamp.now(),
      });
    } catch (error) {
      print("Error reporting post: $error");
    }
  }
}

class ViewPostingScreen extends StatefulWidget {
  // final PostingModel? posting;
  // ViewPostingScreen({Key? key, this.posting}) : super(key: key);

  PostingModel? posting;
  ViewPostingScreen({super.key, this.posting});

  @override
  State<ViewPostingScreen> createState() => _ViewPostingScreenState();
}

class _ViewPostingScreenState extends State<ViewPostingScreen> {
  PostingModel? posting;

  getRequiredInfo() async {
    if (posting != null) {
      await posting!.getAllImagesFromStorage();
      await posting!.getHostFromFirestore();
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    posting = widget.posting;
    getRequiredInfo();
  }

  void reportPost() {
    final report = PostingReport(
      userId: AppConstants.currentUser.id!,
      postId: posting!.id!,
    );
    report.submitReport();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Post reported successfully.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            color: Colors.green,
          ),
        ),
        title: Text('Posting Information'),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite_outline, color: Colors.white),
            onPressed: () {
              AppConstants.currentUser.addSavePosting(posting!);
              Get.snackbar(
                "Success",
                "Added to favorites!",
                backgroundColor: Colors.white,
                colorText: Colors.black,
              );
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'Report') {
                reportPost();
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                PopupMenuItem<String>(
                  value: 'Report',
                  child: Text('Report'),
                ),
              ];
            },
          ),
        ],
      ),
      body: posting == null
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Listing Image
                  AspectRatio(
                    aspectRatio: 3 / 2,
                    child: PageView.builder(
                      itemCount: posting!.displayImages!.length,
                      itemBuilder: (context, index) {
                        MemoryImage currentImage =
                            posting!.displayImages![index];
                        return Image(image: currentImage, fit: BoxFit.fill);
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 5),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Posting Name, Price and Book Now Button
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                posting!.name!.toUpperCase(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Container(
                                  decoration:
                                      const BoxDecoration(color: Colors.green),
                                  child: MaterialButton(
                                    onPressed: () {
                                      Get.to(BookListingScreen(
                                          posting: posting,
                                          hostID: posting!.host!.id!));
                                    },
                                    child: const Text(
                                      'Book now',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  '${posting!.price} /night',
                                  style: const TextStyle(fontSize: 14.0),
                                ),
                              ],
                            ),
                          ],
                        ),
                        // Description, Host Profile Picture, and Name
                        Padding(
                          padding:
                              const EdgeInsets.only(top: 25.0, bottom: 25.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              SizedBox(
                                width: MediaQuery.of(context).size.width / 1.75,
                                child: Text(
                                  posting!.description!,
                                  textAlign: TextAlign.justify,
                                  style: const TextStyle(fontSize: 14),
                                  maxLines: 5,
                                ),
                              ),
                              Column(
                                children: [
                                  GestureDetector(
                                    onTap: () {},
                                    child: CircleAvatar(
                                      radius:
                                          MediaQuery.of(context).size.width /
                                              12.5,
                                      backgroundColor: Colors.black,
                                      child: CircleAvatar(
                                        backgroundImage:
                                            posting!.host!.displayImage,
                                        radius:
                                            MediaQuery.of(context).size.width /
                                                13,
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 20),
                                    child: Text(
                                      posting!.host!.getFullNameOfUser(),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Apartments, Beds, Bathrooms Information
                        Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: ListView(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            children: [
                              PostingInfoTileUI(
                                iconData: Icons.home,
                                category: 'Apartment',
                                categoryInfo:
                                    '${posting!.getGuestsNumber()} guests',
                              ),
                              PostingInfoTileUI(
                                iconData: Icons.hotel,
                                category: 'Beds',
                                categoryInfo: posting!.getBedroomText(),
                              ),
                              PostingInfoTileUI(
                                iconData: Icons.wc,
                                category: 'Bathrooms',
                                categoryInfo: posting!.getBathroomText(),
                              ),
                            ],
                          ),
                        ),
                        // Amenities
                        const Text(
                          'Amenities: ',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 25),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 5.0, bottom: 25),
                          child: GridView.count(
                            shrinkWrap: true,
                            crossAxisCount: 2,
                            childAspectRatio: 3.6,
                            children: List.generate(
                              posting!.amenities!.length,
                              (index) {
                                String currentAmenity =
                                    posting!.amenities![index];
                                return Chip(
                                  label: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20.0),
                                    child: Text(
                                      currentAmenity,
                                      style: const TextStyle(
                                        color: Colors.black45,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  backgroundColor: Colors.white10,
                                );
                              },
                            ),
                          ),
                        ),
                        // Location
                        Padding(
                          padding: const EdgeInsets.only(top: 20, bottom: 10),
                          child: Text(
                            posting!.getFullAddress(),
                            style: const TextStyle(fontSize: 18),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
