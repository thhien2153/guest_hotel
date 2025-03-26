import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:guest_hotel/model/app_constants.dart';
import 'package:guest_hotel/model/posting_model.dart';
import 'package:guest_hotel/view/widgets/calender_ui.dart';

class BookListingScreen extends StatefulWidget {
  final PostingModel? posting;
  final String? hostID;

  BookListingScreen({
    super.key,
    this.posting,
    this.hostID,
  });

  @override
  State<BookListingScreen> createState() => _BookListingScreenState();
}

class _BookListingScreenState extends State<BookListingScreen> {
  PostingModel? posting;
  List<DateTime> bookedDates = [];
  List<DateTime> selectedDates = [];
  List<CalenderUI> calendarWidgets = [];

  _buildCalendarWidgets() {
    for (int i = 0; i < 12; i++) {
      calendarWidgets.add(CalenderUI(
        monthIndex: i,
        bookedDates: bookedDates,
        selectDate: _selectDate,
        getSelectedDates: _getSelectedDates,
      ));
      setState(() {});
    }
  }

  List<DateTime> _getSelectedDates() {
    return selectedDates;
  }

  _selectDate(DateTime date) {
    if (selectedDates.contains(date)) {
      selectedDates.remove(date);
    } else {
      selectedDates.add(date);
    }
    selectedDates.sort();
    setState(() {});
  }

  _localBookedDates() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('postings')
          .doc(posting!.id)
          .collection('bookings')
          .get();

      for (var doc in snapshot.docs) {
        List<dynamic> dates = doc['dates'];
        dates.forEach((date) {
          bookedDates.add(DateTime.parse(date));
        });
      }

      _buildCalendarWidgets();
    } catch (error) {
      print("Error fetching booked dates: $error");
    }
  }

  @override
  void initState() {
    super.initState();
    posting = widget.posting;
    _localBookedDates();
  }

  void _showBookingDetailsDialog() {
    final TextEditingController idController = TextEditingController();
    final TextEditingController nameController = TextEditingController();
    final TextEditingController phoneController = TextEditingController();
    final TextEditingController emailController = TextEditingController();
    final TextEditingController noteController = TextEditingController();

    String checkInDate = selectedDates.isNotEmpty
        ? selectedDates.first.toString().split(' ')[0]
        : "Not selected";
    String checkOutDate = selectedDates.length > 1
        ? selectedDates.last.toString().split(' ')[0]
        : "Not selected";

    // Tính tổng số ngày đã chọn
    int totalDays = selectedDates.length;

    // Tính tổng giá tiền
    double totalPrice = totalDays * (posting?.price ?? 0.0);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            "Enter Personal Information",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          content: SingleChildScrollView(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTextField(
                    controller: idController,
                    hintText: "Identification Code",
                  ),
                  const SizedBox(height: 15),
                  _buildTextField(
                    controller: nameController,
                    hintText: "Full Name",
                  ),
                  const SizedBox(height: 15),
                  _buildTextField(
                    controller: phoneController,
                    hintText: "Phone Number",
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 15),
                  _buildTextField(
                    controller: emailController,
                    hintText: "Email",
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 15),
                  _buildTextField(
                    readOnly: true,
                    hintText: "Check-in Date",
                    labelText: checkInDate,
                  ),
                  const SizedBox(height: 15),
                  _buildTextField(
                    readOnly: true,
                    hintText: "Check-out Date",
                    labelText: checkOutDate,
                  ),
                  const SizedBox(height: 15),
                  _buildTextField(
                    controller: noteController,
                    hintText: "Notes (optional)",
                  ),
                  const SizedBox(height: 15),
                  // Hiển thị tổng giá tiền
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Total:",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      Text(
                        "\ ${(totalPrice % 1 == 0 ? totalPrice.toInt() : totalPrice).toString()}",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                "Close",
                style: TextStyle(color: Colors.red),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
              child: Text("Confirm"),
              onPressed: () async {
                if (idController.text.isEmpty ||
                    nameController.text.isEmpty ||
                    phoneController.text.isEmpty ||
                    emailController.text.isEmpty ||
                    selectedDates.isEmpty) {
                  Get.snackbar(
                    "Error",
                    "Please fill in all required fields.",
                    backgroundColor: Colors.white,
                    colorText: Colors.red,
                  );
                } else {
                  try {
                    // Ép kiểu userID thành String
                    String userID = AppConstants.currentUser.id ?? '';

                    // Tạo dữ liệu đặt phòng
                    Map<String, dynamic> bookingData = {
                      'dates': selectedDates
                          .map((date) => date.toIso8601String())
                          .toList(),
                      'name': nameController.text,
                      'userID': userID,
                      'postingID': widget.posting!.id,
                      'phone': phoneController.text,
                      'email': emailController.text,
                      'note': noteController.text,
                      'createdAt': DateTime.now().toIso8601String(),
                      'totalPrice':
                          totalPrice, // Lưu tổng giá tiền vào cơ sở dữ liệu
                    };

                    // Lưu thông tin đặt phòng vào bảng bookings
                    await FirebaseFirestore.instance
                        .collection('bookings')
                        .add(bookingData);

                    // Hiển thị thông báo thành công
                    Get.snackbar(
                      "Success",
                      "Your booking has been confirmed!",
                      backgroundColor: Colors.white,
                      colorText: Colors.black,
                    );

                    // Đóng dialog
                    Navigator.of(context).pop();
                  } catch (e) {
                    // Hiển thị thông báo lỗi
                    Get.snackbar(
                      "Error",
                      "Failed to save booking. Please try again.",
                      backgroundColor: Colors.red,
                      colorText: Colors.white,
                    );
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildTextField({
    TextEditingController? controller,
    String? hintText,
    String? labelText,
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15.0),
      decoration: BoxDecoration(
        color: const Color(0xFFececf8),
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        readOnly: readOnly,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hintText,
          labelText: labelText,
          hintStyle: TextStyle(color: Colors.grey),
        ),
      ),
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
          "Book ${posting!.name}",
          style: const TextStyle(
            color: Colors.white,
            fontSize: 21,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(25, 25, 25, 0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            const Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                Text('Sun'),
                Text('Mon'),
                Text('Tues'),
                Text('Wed'),
                Text('Thurs'),
                Text('Fri'),
                Text('Sat'),
              ],
            ),
            SizedBox(
              height: MediaQuery.of(context).size.height / 2,
              child: (calendarWidgets.isEmpty)
                  ? Container()
                  : PageView.builder(
                      itemCount: calendarWidgets.length,
                      itemBuilder: (context, index) {
                        return calendarWidgets[index];
                      },
                    ),
            ),
            selectedDates.isNotEmpty
                ? MaterialButton(
                    onPressed: _showBookingDetailsDialog,
                    minWidth: double.infinity,
                    height: MediaQuery.of(context).size.height / 14,
                    color: Colors.green,
                    child: const Text(
                      'Book Now',
                      style: TextStyle(color: Colors.white),
                    ),
                  )
                : Container(),
          ],
        ),
      ),
    );
  }
}
