import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:guest_hotel/global.dart';
import 'package:guest_hotel/view/signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formkey = GlobalKey<FormState>();
  final TextEditingController _emailTextEditingController =
      TextEditingController();
  final TextEditingController _passwordTextEditingController =
      TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(color: Colors.green),
        child: ListView(
          children: [
            Image.asset(
              "images/login.png",
            ),
            const SizedBox(height: 20),
            const Center(
              child: Text(
                "LOGIN PAGE",
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 3,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),
            Form(
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
                      validator: (valueEmail) {
                        if (valueEmail == null || valueEmail.isEmpty) {
                          return "Please enter your Email";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 15),
                    _buildTextField(
                      controller: _passwordTextEditingController,
                      hintText: "Password",
                      obscureText: true,
                      validator: (valuePassword) {
                        if (valuePassword!.length < 5) {
                          return "Password too weak";
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: ElevatedButton(
                onPressed: () async {
                  if (_formkey.currentState!.validate()) {
                    await userViewModel.login(
                      _emailTextEditingController.text.trim(),
                      _passwordTextEditingController.text.trim(),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                ),
                child: const Text(
                  "LOGIN",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 30,
                    color: Colors.green,
                  ),
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Get.to(const SignupScreen());
              },
              child: const Text(
                "Don't have an account? Create here",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
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
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        hintText: hintText,
        border: OutlineInputBorder(),
        fillColor: Colors.white,
        filled: true,
      ),
      style: const TextStyle(
        fontSize: 18,
        color: Colors.black,
      ),
    );
  }
}
