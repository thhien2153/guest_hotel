import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:guest_hotel/global.dart';
import 'package:guest_hotel/model/app_constants.dart';
import 'package:guest_hotel/view/guestScreens/user_profile_screen.dart';
import 'package:guest_hotel/view/guest_home_screen.dart';
import 'package:guest_hotel/view/login_screen.dart';

import 'host_home_screen.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  String _hostingTitle = 'Show my Host Dashboard';

  modifyHostingMode() async {
    if (AppConstants.currentUser.isHost!) {
      if (AppConstants.currentUser.isCurrentlyHosting!) {
        AppConstants.currentUser.isCurrentlyHosting = false;

        Get.to(const GuestHomeScreen());
      } else {
        AppConstants.currentUser.isCurrentlyHosting = true;

        Get.to(HostHomeScreen());
      }
    } else {
      await userViewModel.becomeHost(FirebaseAuth.instance.currentUser!.uid);

      AppConstants.currentUser.isCurrentlyHosting = true;

      Get.to(HostHomeScreen());
    }
  }

  Future<void> logout() async {
    try {
      // Xử lý đăng xuất
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    } catch (error) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Logout Failed'),
          content: Text(error.toString()),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> showLogoutConfirmationDialog() async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirm Logout'),
          content: const Text('Do you want to log out of this account?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Đóng dialog
              },
              child: const Text('No'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Đóng dialog
                logout(); // Thực hiện logout
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Yes'),
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    if (AppConstants.currentUser.isHost!) {
      if (AppConstants.currentUser.isCurrentlyHosting!) {
        _hostingTitle = 'Show my Guest Dashboard';
      } else {
        _hostingTitle = 'Show my Host Dashboard';
      }
    } else {
      _hostingTitle = 'You are become a host';
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
        child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // user infor
                Padding(
                  padding: const EdgeInsets.only(bottom: 30),
                  child: Center(
                    child: Column(
                      children: [
                        //image
                        MaterialButton(
                          onPressed: () {},
                          child: CircleAvatar(
                            backgroundColor: Colors.black,
                            radius: MediaQuery.of(context).size.width / 4.5,
                            child: CircleAvatar(
                              backgroundImage:
                                  AppConstants.currentUser.displayImage,
                              radius: MediaQuery.of(context).size.width / 4.6,
                            ),
                          ),
                        ),

                        const SizedBox(
                          height: 10,
                        ),

//name and email
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              AppConstants.currentUser.getFullNameOfUser(),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                            Text(
                              AppConstants.currentUser.email.toString(),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            )
                          ],
                        )
                      ],
                    ),
                  ),
                ),

                ListView(
                  shrinkWrap: true,
                  children: [
                    // Personal Information Button
                    Container(
                      decoration: const BoxDecoration(color: Colors.green),
                      child: MaterialButton(
                        height: MediaQuery.of(context).size.height / 9,
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => UserProfileScreen()),
                          );
                        },
                        child: const ListTile(
                          contentPadding: EdgeInsets.all(0.0),
                          leading: Text(
                            "Personal Information",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                          trailing: Icon(
                            size: 34,
                            Icons.person_outlined,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 10,
                    ),

                    //Change Hosting Button
                    Container(
                      decoration: const BoxDecoration(color: Colors.green),
                      child: MaterialButton(
                        height: MediaQuery.of(context).size.height / 9,
                        onPressed: () {
                          modifyHostingMode();

                          setState(() {});
                        },
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(0.0),
                          leading: Text(
                            _hostingTitle,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                          trailing: const Icon(
                            size: 34,
                            Icons.home_outlined,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 10,
                    ),

                    //Logout
                    Container(
                      decoration: const BoxDecoration(color: Colors.green),
                      child: MaterialButton(
                        height: MediaQuery.of(context).size.height / 9,
                        onPressed: () {
                          showLogoutConfirmationDialog();
                        },
                        child: const ListTile(
                          contentPadding: EdgeInsets.all(0.0),
                          leading: Text(
                            "Logout",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                          trailing: Icon(
                            size: 34,
                            Icons.logout_outlined,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 20,
                    ),
                  ],
                )
              ],
            )));
  }
}
