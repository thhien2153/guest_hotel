import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get/get.dart';
import 'package:guest_hotel/model/app_constants.dart';
import 'package:image_picker/image_picker.dart';

class UserProfileScreen extends StatefulWidget {
  @override
  _UserProfileScreenState createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController countryController = TextEditingController();
  final TextEditingController bioController = TextEditingController();

  ImageProvider displayImage = AssetImage('assets/default_avatar.png');

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      firstNameController.text = AppConstants.currentUser.firstName ?? '';
      lastNameController.text = AppConstants.currentUser.lastName ?? '';
      emailController.text = AppConstants.currentUser.email ?? '';
      cityController.text = AppConstants.currentUser.city ?? '';
      countryController.text = AppConstants.currentUser.country ?? '';
      bioController.text = AppConstants.currentUser.bio ?? '';
      displayImage = AppConstants.currentUser.displayImage ?? displayImage;
    });
  }

  Future<void> _updateUserData() async {
    String currentUserID = AppConstants.currentUser.id!;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserID)
        .update({
      'firstName': firstNameController.text,
      'lastName': lastNameController.text,
      'email': emailController.text,
      'city': cityController.text,
      'country': countryController.text,
      'bio': bioController.text,
    });
    AppConstants.currentUser.firstName = firstNameController.text;
    AppConstants.currentUser.lastName = lastNameController.text;
    AppConstants.currentUser.email = emailController.text;
    AppConstants.currentUser.city = cityController.text;
    AppConstants.currentUser.country = countryController.text;
    AppConstants.currentUser.bio = bioController.text;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Profile updated successfully')),
    );
  }

  Future<void> _pickImage() async {
    final ImagePicker _picker = ImagePicker();
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    final bytes = await image.readAsBytes();
    String currentUserID = AppConstants.currentUser.id!;
    Reference storageReference = FirebaseStorage.instance
        .ref()
        .child("userImages")
        .child(currentUserID)
        .child(currentUserID + ".png");

    await storageReference.putData(bytes);
    setState(() {
      displayImage = MemoryImage(bytes);
      AppConstants.currentUser.displayImage = displayImage as MemoryImage?;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('User Profile'),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: Center(
                  child: CircleAvatar(
                    backgroundImage: displayImage,
                    radius: 60,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _buildTextField(
                controller: firstNameController,
                hintText: 'First Name',
              ),
              const SizedBox(height: 15),
              _buildTextField(
                controller: lastNameController,
                hintText: 'Last Name',
              ),
              const SizedBox(height: 15),
              _buildTextField(
                controller: emailController,
                hintText: 'Email',
                readOnly: true,
              ),
              const SizedBox(height: 15),
              _buildTextField(
                controller: cityController,
                hintText: 'City',
              ),
              const SizedBox(height: 15),
              _buildTextField(
                controller: countryController,
                hintText: 'Country',
              ),
              const SizedBox(height: 15),
              _buildTextField(
                controller: bioController,
                hintText: 'Bio',
              ),
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    _updateUserData();
                    Get.snackbar(
                      "Success",
                      "Your personal information has been updated.",
                    );
                  },
                  child: const Text(
                    "Update",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: Colors.green,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    bool readOnly = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hintText,
        border: OutlineInputBorder(),
      ),
    );
  }
}
