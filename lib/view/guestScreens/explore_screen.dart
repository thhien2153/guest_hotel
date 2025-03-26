import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:guest_hotel/model/posting_model.dart';
import 'package:guest_hotel/view/view_posting_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  TextEditingController controllerSearch = TextEditingController();
  Stream stream = FirebaseFirestore.instance.collection('postings').snapshots();
  String searchType = "";

  bool isNameButtonSelected = false;
  bool isCityButtonSelected = false;
  bool isPriceButtonSelected = false;

  Future<String?> getImageUrl(String? imageName, String? postingId) async {
    if (imageName == null || postingId == null) return null;
    try {
      Reference ref = FirebaseStorage.instance
          .ref()
          .child("postingImages")
          .child(postingId)
          .child(imageName);
      String url = await ref.getDownloadURL();
      return url;
    } catch (e) {
      print("Error getting image URL: $e");
      return null;
    }
  }

  void searchByField() {
    setState(() {
      if (searchType.isNotEmpty) {
        if (searchType == "price") {
          double? price = double.tryParse(controllerSearch.text);
          if (price != null) {
            stream = FirebaseFirestore.instance
                .collection('postings')
                .where(searchType, isEqualTo: price)
                .snapshots();
          }
        } else {
          stream = FirebaseFirestore.instance
              .collection('postings')
              .where(searchType, isEqualTo: controllerSearch.text)
              .snapshots();
        }
      }
    });
  }

  void pressSearchByButton(String searchTypeStr, bool isNameButtonSelectedB,
      bool isCityButtonSelectedB, bool isPriceButtonSelectedB) {
    setState(() {
      searchType = searchTypeStr;
      isNameButtonSelected = isNameButtonSelectedB;
      isCityButtonSelected = isCityButtonSelectedB;
      isPriceButtonSelected = isPriceButtonSelectedB;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 30, 20, 10),
      child: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 0, bottom: 0),
              child: TextField(
                decoration: const InputDecoration(
                    hintText: 'Search',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Colors.grey,
                        width: 2.0,
                      ),
                    ),
                    contentPadding: EdgeInsets.all(5.0)),
                style: const TextStyle(
                  fontSize: 20.0,
                  color: Colors.black,
                ),
                controller: controllerSearch,
                onEditingComplete: searchByField,
              ),
            ),
            SizedBox(
              height: 70,
              width: MediaQuery.of(context).size.width,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.all(20),
                children: [
                  MaterialButton(
                    onPressed: () {
                      pressSearchByButton("name", true, false, false);
                    },
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    color: isNameButtonSelected ? Colors.green : Colors.white,
                    child: const Text("Name"),
                  ),
                  const SizedBox(width: 10),
                  MaterialButton(
                    onPressed: () {
                      pressSearchByButton("city", false, true, false);
                    },
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    color: isCityButtonSelected ? Colors.green : Colors.white,
                    child: const Text("City"),
                  ),
                  const SizedBox(width: 10),
                  MaterialButton(
                    onPressed: () {
                      pressSearchByButton("price", false, false, true);
                    },
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    color: isPriceButtonSelected ? Colors.green : Colors.white,
                    child: const Text("Price"),
                  ),
                  const SizedBox(width: 10),
                  MaterialButton(
                    onPressed: () {
                      controllerSearch.clear();
                      pressSearchByButton("", false, false, false);
                    },
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    color: Colors.white,
                    child: const Text("Clear"),
                  ),
                ],
              ),
            ),
            StreamBuilder(
                stream: stream,
                builder: (context, dataSnapshots) {
                  if (dataSnapshots.hasData) {
                    return GridView.builder(
                      physics: const ScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: dataSnapshots.data.docs.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 15,
                        childAspectRatio: 3 / 4,
                      ),
                      itemBuilder: (context, index) {
                        DocumentSnapshot snapshot =
                            dataSnapshots.data.docs[index];
                        PostingModel cPosting = PostingModel(id: snapshot.id);
                        cPosting.getPostingInfoFromSnapshot(snapshot);

                        return FutureBuilder<String?>(
                          future: getImageUrl(
                              cPosting.imageNames?.first, cPosting.id),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.done) {
                              return InkResponse(
                                onTap: () {
                                  Get.to(ViewPostingScreen(
                                    posting: cPosting,
                                  ));
                                },
                                enableFeedback: true,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    snapshot.hasData &&
                                            snapshot.data!.isNotEmpty
                                        ? Image.network(
                                            snapshot.data!,
                                            fit: BoxFit.cover,
                                            height: 100,
                                            width: double.infinity,
                                          )
                                        : const Text("No Image"),
                                    Text(
                                      cPosting.name ?? "Unknown",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      "${cPosting.price ?? 0}/night",
                                    ),
                                    Row(
                                      children: List.generate(5, (starIndex) {
                                        return Icon(
                                          starIndex < (cPosting.rating ?? 0)
                                              ? Icons.star
                                              : Icons.star_border,
                                          color: Colors.green,
                                        );
                                      }),
                                    ),
                                  ],
                                ),
                              );
                            } else {
                              return const CircularProgressIndicator();
                            }
                          },
                        );
                      },
                    );
                  } else {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }
                }),
          ],
        ),
      ),
    );
  }
}
