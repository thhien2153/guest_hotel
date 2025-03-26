import 'package:curved_navigation_bar/curved_navigation_bar.dart';

import 'package:flutter/material.dart';
import 'package:guest_hotel/view/admin_screen/adminhome.dart';
import 'package:guest_hotel/view/admin_screen/adminpost.dart';
import 'package:guest_hotel/view/admin_screen/adminprofile.dart';
import 'package:guest_hotel/view/admin_screen/adminuser.dart';

class Bottomnav extends StatefulWidget {
  const Bottomnav({super.key});

  @override
  State<Bottomnav> createState() => _BottomnavState();
}

class _BottomnavState extends State<Bottomnav> {
  int currentTabIndex = 0;

  late List<Widget> pages;
  late Widget currentPage;
  late AdminHome adminHome;
  late AdminPost adminPost;
  late AdminUser adminUser;
  late AdminProfile adnimProfile;

  @override
  void initState() {
    adminHome = AdminHome();
    adminPost = AdminPost();
    adminUser = AdminUser();
    adnimProfile = AdminProfile();

    pages = [adminHome, adminUser, adminPost, adnimProfile];
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min, // Đảm bảo kích thước cột tối thiểu
        children: [
          CurvedNavigationBar(
            height: 50,
            backgroundColor: Colors.white,
            color: const Color(0xFF15A362),
            animationDuration:
                const Duration(milliseconds: 500), // Đổi thành milliseconds
            onTap: (int index) {
              setState(() {
                currentTabIndex = index;
              });
            },
            items: const [
              Icon(Icons.home_outlined, color: Colors.white),
              Icon(Icons.admin_panel_settings, color: Colors.white),
              Icon(Icons.receipt_long_outlined, color: Colors.white),
              Icon(Icons.person_outline, color: Colors.white),
            ],
          ),
          // Phần tên tab nằm dưới biểu tượng của thanh điều hướng
        ],
      ),
      body: pages[currentTabIndex],
    );
  }
}
