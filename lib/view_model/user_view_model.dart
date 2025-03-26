import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:guest_hotel/model/app_constants.dart';
import 'package:guest_hotel/view/admin_screen/adminbottomnav.dart';
import 'package:guest_hotel/view/guest_home_screen.dart';

import '../model/user_model.dart';

class UserViewModel {
  UserModel userModel = UserModel();

  signUp(email, password, firstName, lastName, city, country, bio,
      imageFileOfUser) async {
    Get.snackbar("Please wait", "Your account is being created.");

    try {
      await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: email,
        password: password,
      )
          .then((result) async {
        String currentUserID = result.user!.uid;

        AppConstants.currentUser.id = currentUserID;
        AppConstants.currentUser.firstName = firstName;
        AppConstants.currentUser.lastName = lastName;
        AppConstants.currentUser.city = city;
        AppConstants.currentUser.country = country;
        AppConstants.currentUser.bio = bio;
        AppConstants.currentUser.email = email;
        AppConstants.currentUser.password = password;

        await saveUserToFirestore(
                bio, city, country, email, firstName, lastName, currentUserID)
            .whenComplete(() async {
          addImageToFirebaseStorage(imageFileOfUser, currentUserID);
        });

        Get.snackbar("Congratulations", "Your account has been created.");
      });
    } catch (e) {
      Get.to(const GuestHomeScreen());
      Get.snackbar("Error!!!", e.toString());
    }
  }

  Future<void> saveUserToFirestore(
      bio, city, country, email, firstName, lastName, id) async {
    Map<String, dynamic> dataMap = {
      "bio": bio,
      "city": city,
      "country": country,
      "email": email,
      "firstName": firstName,
      "lastName": lastName,
      "isHost": false,
      "myPostingIDs": [],
      "savedPostingIDs": [],
      "earnings": 0,
      "role": "user" // Added role field with default value 'user'
    };

    await FirebaseFirestore.instance.collection("users").doc(id).set(dataMap);
  }

  addImageToFirebaseStorage(File imageFileOfUser, currentUserID) async {
    Reference referenceStorage = FirebaseStorage.instance
        .ref()
        .child("userImages")
        .child(currentUserID)
        .child(currentUserID + ".png");

    await referenceStorage.putFile(imageFileOfUser).whenComplete(() {});

    AppConstants.currentUser.displayImage =
        MemoryImage(imageFileOfUser.readAsBytesSync());
  }

  login(email, password) async {
    Get.snackbar("Please wait", "Checking your credentials...");
    try {
      FirebaseAuth.instance
          .signInWithEmailAndPassword(
        email: email,
        password: password,
      )
          .then((result) async {
        String currentUserID = result.user!.uid;
        AppConstants.currentUser.id = currentUserID;

        await getUserInfoFromFirestore(currentUserID);
        await getImageFromStorage(currentUserID);

        await AppConstants.currentUser.getMyPostingsFromFirestore();

        // Check role and navigate accordingly
        if (AppConstants.currentUser.role == "user") {
          Get.snackbar("Login Successful", "You have logged in successfully");
          Get.to(const GuestHomeScreen());
        } else if (AppConstants.currentUser.role == "admin") {
          Get.snackbar("Login Successful", "Welcome, Admin");
          Get.to(Bottomnav());
        }
      });
    } catch (e) {
      Get.snackbar("Error!!!", e.toString());
    }
  }

  Future<void> getUserInfoFromFirestore(String userID) async {
    DocumentSnapshot snapshot =
        await FirebaseFirestore.instance.collection('users').doc(userID).get();
    AppConstants.currentUser.snapshot = snapshot;
    AppConstants.currentUser.firstName = snapshot['firstName'] ?? " ";
    AppConstants.currentUser.lastName = snapshot['lastName'] ?? "";
    AppConstants.currentUser.email = snapshot['email'] ?? "";
    AppConstants.currentUser.bio = snapshot['bio'] ?? "";
    AppConstants.currentUser.city = snapshot['city'] ?? "";
    AppConstants.currentUser.country = snapshot['country'] ?? "";
    AppConstants.currentUser.isHost = snapshot['isHost'] ?? false;
    AppConstants.currentUser.role = snapshot['role'] ?? "";
  }

  getImageFromStorage(userID) async {
    if (AppConstants.currentUser.displayImage != null) {
      return AppConstants.currentUser.displayImage;
    }
    final imageDataInBytes = await FirebaseStorage.instance
        .ref()
        .child("userImages")
        .child(userID)
        .child(userID + ".png")
        .getData(1024 * 1024);

    AppConstants.currentUser.displayImage = MemoryImage(imageDataInBytes!);

    return AppConstants();
  }

  becomeHost(String userID) async {
    userModel.isHost = true;

    Map<String, dynamic> dataMap = {
      "isHost": true,
    };
    await FirebaseFirestore.instance
        .collection("users")
        .doc(userID)
        .update(dataMap);
  }

  modifyCurrentlyHosting(bool isHosting) {
    userModel.isCurrentlyHosting = isHosting;
  }
}
