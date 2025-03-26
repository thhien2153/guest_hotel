import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:guest_hotel/global.dart';
import 'package:guest_hotel/view/login_screen.dart';
import 'package:image_picker/image_picker.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _emailTextEditingController =
      TextEditingController();
  final TextEditingController _passwordTextEditingController =
      TextEditingController();
  final TextEditingController _firstNameTextEditingController =
      TextEditingController();
  final TextEditingController _lastNameTextEditingController =
      TextEditingController();
  final TextEditingController _cityTextEditingController =
      TextEditingController();
  final TextEditingController _countryTextEditingController =
      TextEditingController();
  final TextEditingController _bioTextEditingController =
      TextEditingController();

  final _formkey = GlobalKey<FormState>();

  File? imageFileOfUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(color: Colors.green),
        ),
        title: const Text(
          "SIGN UP PAGE",
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Container(
        padding: const EdgeInsets.only(top: 20),
        decoration: const BoxDecoration(color: Colors.green),
        child: ListView(
          children: [
            Image.asset(
              "images/signup.png",
            ),
            const SizedBox(height: 20),
            const Center(
              child: Text(
                "SIGN UP PAGE",
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 3,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Form(
                key: _formkey,
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTextField(
                        controller: _emailTextEditingController,
                        hintText: "Email",
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 15),
                      _buildTextField(
                        controller: _passwordTextEditingController,
                        hintText: "Password",
                        obscureText: true,
                      ),
                      const SizedBox(height: 15),
                      _buildTextField(
                        controller: _firstNameTextEditingController,
                        hintText: "First Name",
                      ),
                      const SizedBox(height: 15),
                      _buildTextField(
                        controller: _lastNameTextEditingController,
                        hintText: "Last Name",
                      ),
                      const SizedBox(height: 15),
                      _buildTextField(
                        controller: _cityTextEditingController,
                        hintText: "City",
                      ),
                      const SizedBox(height: 15),
                      _buildTextField(
                        controller: _countryTextEditingController,
                        hintText: "Country",
                      ),
                      const SizedBox(height: 15),
                      _buildTextField(
                        controller: _bioTextEditingController,
                        hintText: "Bio",
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: MaterialButton(
                onPressed: () async {
                  var imageFile = await ImagePicker()
                      .pickImage(source: ImageSource.gallery);

                  if (imageFile != null) {
                    imageFileOfUser = File(imageFile.path);
                    setState(() {
                      imageFileOfUser;
                    });
                  }
                },
                child: imageFileOfUser == null
                    ? const Icon(Icons.add_a_photo_outlined)
                    : CircleAvatar(
                        radius: MediaQuery.of(context).size.width / 5.0,
                        backgroundColor: Colors.green,
                        backgroundImage: FileImage(imageFileOfUser!),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 20, left: 40),
              child: ElevatedButton(
                onPressed: () async {
                  if (!_formkey.currentState!.validate() ||
                      imageFileOfUser == null) {
                    Get.snackbar(
                      "Field Missing",
                      "Please choose an image and fill out the complete sign-up form.",
                    );
                    return;
                  }

                  try {
                    bool isSuccess = await userViewModel.signUp(
                      _emailTextEditingController.text.trim(),
                      _passwordTextEditingController.text.trim(),
                      _firstNameTextEditingController.text.trim(),
                      _lastNameTextEditingController.text.trim(),
                      _cityTextEditingController.text.trim(),
                      _countryTextEditingController.text.trim(),
                      _bioTextEditingController.text.trim(),
                      imageFileOfUser!,
                    );

                    if (isSuccess) {
                      Get.snackbar(
                        "Success",
                        "Account created successfully! Redirecting to login page...",
                      );
                      Get.off(() => const LoginScreen());
                    } else {
                      Get.snackbar(
                        "Error",
                        "Sign-up failed. Please try again.",
                      );
                    }
                  } catch (e) {
                    Get.snackbar(
                      "Error",
                      "An unexpected error occurred: $e",
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                ),
                child: const Text(
                  "SIGN UP",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 30,
                    color: Colors.green,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hintText,
        border: OutlineInputBorder(),
        fillColor: Colors.white,
        filled: true,
      ),
    );
  }
}
