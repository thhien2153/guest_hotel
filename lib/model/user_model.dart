import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:guest_hotel/model/app_constants.dart';
import 'package:guest_hotel/model/booking_model.dart';
import 'package:guest_hotel/model/contact_model.dart';
import 'package:guest_hotel/model/conversation_model.dart';
import 'package:guest_hotel/model/posting_model.dart';
import 'package:guest_hotel/model/review_model.dart';

class UserModel extends ContactModel {
  String? email;
  String? password;
  String? bio;
  String? city;
  String? country;
  bool? isHost;
  bool? isCurrentlyHosting;
  DocumentSnapshot? snapshot;

  List<BookingModel>? bookings;
  List<ReviewModel>? reviews;
  List<PostingModel>? savedPostings;
  List<PostingModel>? myPostings;

  String? role;

  UserModel({
    String super.id,
    String super.firstName,
    String super.lastName,
    super.displayImage,
    this.email = "",
    this.bio = "",
    this.city = "",
    this.country = "",
  }) {
    isHost = false;
    isCurrentlyHosting = false;

    bookings = [];
    reviews = [];

    savedPostings = [];
    myPostings = [];
  }

  createContactFromUser() {
    return ContactModel(
      id: id,
      firstName: firstName,
      lastName: lastName,
      displayImage: displayImage,
    );
  }

  Future<List<PostingModel>> getPostings() async {
    List<PostingModel> postingList = [];
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('postings')
        .where('hostID', isEqualTo: id)
        .get();

    for (var doc in snapshot.docs) {
      PostingModel posting = PostingModel(id: doc.id);
      await posting.getPostingInfoFromSnapshot(doc);
      postingList.add(posting);
    }

    return postingList;
  }

  Future<List<BookingModel>> getBookings() async {
    List<BookingModel> bookingList = [];
    List<PostingModel> postings = await getPostings();
    List<String> postingIDs = postings.map((posting) => posting.id!).toList();

    for (String postingID in postingIDs) {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where('postingID', isEqualTo: postingID)
          .get();

      for (var doc in snapshot.docs) {
        BookingModel booking = BookingModel();
        booking.id = doc.id;
        booking.dates = List<DateTime>.from(
            doc['dates'].map((date) => DateTime.parse(date)));
        bookingList.add(booking);
      }
    }

    return bookingList;
  }

  addPostingToMyPostings(PostingModel posting) async {
    myPostings!.add(posting);

    List<String> myPostingIDsList = [];

    for (var element in myPostings!) {
      myPostingIDsList.add(element.id!);
    }

    await FirebaseFirestore.instance.collection("users").doc(id).update({
      'myPostingIDs': myPostingIDsList,
    });
  }

  getMyPostingsFromFirestore() async {
    List<String> myPostingIDs =
        List<String>.from(snapshot!["myPostingIDs"]) ?? [];

    for (String postingID in myPostingIDs) {
      PostingModel posting = PostingModel(id: postingID);
      await posting.getPostingInfoFromFirestore();
      await posting.getAllBookingsFromFirestore();
      await posting.getAllImagesFromStorage();

      myPostings!.add(posting);
    }
  }

  addSavePosting(PostingModel posting) async {
    for (var savedPosting in savedPostings!) {
      if (savedPosting.id == posting.id) {
        return;
      }
    }

    savedPostings!.add(posting);

    List<String> savedPostingIDs = [];

    savedPostings!.forEach((savedPosting) {
      savedPostingIDs.add(savedPosting.id!);
    });

    await FirebaseFirestore.instance.collection("user").doc(id).update({
      'savedPostingIDs': savedPostingIDs,
    });
    Get.snackbar("Marked as Favourite", "Saved to your Favourite List");
  }

  removeSavedPosting(PostingModel posting) async {
    for (int i = 0; i < savedPostings!.length; i++) {
      if (savedPostings![i].id == posting.id) {
        savedPostings!.removeAt(i);
        break;
      }
    }
    List<String> savedPostingIDs = [];

    savedPostings!.forEach((savedPosting) {
      savedPostingIDs.add(savedPosting.id!);
    });

    await FirebaseFirestore.instance.collection("user").doc(id).update({
      'savedPostingIDs': savedPostingIDs,
    });

    Get.snackbar("Listing Removed", "Listing removed from your Favourite List");
  }

  Future<void> addBookingToFirestore(BookingModel booking,
      double totalPriceForAllNights, String hostID) async {
    Map<String, dynamic> data = {
      'dates': booking.dates,
      'postingID': booking.posting!.id!,
    };
    await FirebaseFirestore.instance
        .doc('user/${id}/bookings/${booking.id}')
        .set(data);

    String earningOld = "";

    await FirebaseFirestore.instance
        .collection("user")
        .doc(hostID)
        .get()
        .then((dataSnap) {
      earningOld = dataSnap["earnings"].toString();
    });

    await FirebaseFirestore.instance.collection("users").doc(hostID).update({
      "earnings": totalPriceForAllNights + int.parse(earningOld),
    });
    bookings!.add(booking);

    await addBookingConversation(booking);
  }

  addBookingConversation(BookingModel booking) async {
    ConversationModel conversation = ConversationModel();
    conversation.addConversationToFirestore(booking.posting!.host!);

    String textMessage =
        "Hi my name is ${AppConstants.currentUser!.firstName} and I have"
        "just booked ${booking.posting!.name} from ${booking.dates!.first} to"
        "${booking.dates!.last} if you have any questions contact me. Enjoy your"
        "stay!";

    await conversation.addMessageToFirestore(textMessage);
  }

  List<DateTime> getAllBookedDates() {
    List<DateTime> allBookedDates = [];
    myPostings!.forEach((posting) {
      posting.bookings!.forEach((booking) {
        allBookedDates.addAll(booking.dates!);
      });
    });

    return allBookedDates;
  }
}
