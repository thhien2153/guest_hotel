import 'package:flutter/material.dart';
import 'package:guest_hotel/view/guestScreens/account_screen.dart';
import 'package:guest_hotel/view/guestScreens/chatbot_screen.dart';
import 'package:guest_hotel/view/guestScreens/explore_screen.dart';
import 'package:guest_hotel/view/guestScreens/saved_listing_screen.dart';
import 'package:guest_hotel/view/guestScreens/trips_screen.dart';

class GuestHomeScreen extends StatefulWidget {
  const GuestHomeScreen({super.key});

  @override
  State<GuestHomeScreen> createState() => _GuestHomeScreenState();
}

class _GuestHomeScreenState extends State<GuestHomeScreen> {
  int selectedIndex = 0;

  final List<String> screenTitles = [
    'Explore',
    'Saved',
    'ChatAI',
    'Trips',
    'Profile',
  ];

  final List<Widget> screens = [
    const ExploreScreen(),
    const SavedListingsScreen(),
    const ChatbotScreen(),
    const TripsScreen(),
    const AccountScreen(),
  ];

  BottomNavigationBarItem customNavigationBarItem(
      int index, IconData iconData, String title) {
    return BottomNavigationBarItem(
      icon: Icon(
        iconData,
        color: Colors.black,
      ),
      activeIcon: Icon(
        iconData,
        color: Colors.green,
      ),
      label: title,
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
        title: Text(
          screenTitles[selectedIndex],
          style: const TextStyle(
            fontSize: 18,
            color: Colors.white,
          ),
        ),
        automaticallyImplyLeading: false,
        centerTitle: true,
      ),
      body: screens[selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        onTap: (i) {
          setState(() {
            selectedIndex = i;
          });
        },
        currentIndex: selectedIndex,
        type: BottomNavigationBarType.fixed,
        items: <BottomNavigationBarItem>[
          customNavigationBarItem(0, Icons.search, screenTitles[0]),
          customNavigationBarItem(1, Icons.favorite, screenTitles[1]),
          customNavigationBarItem(2, Icons.question_answer, screenTitles[2]),
          customNavigationBarItem(3, Icons.home_outlined, screenTitles[3]),
          customNavigationBarItem(4, Icons.person_outlined, screenTitles[4]),
        ],
      ),
    );
  }
}
