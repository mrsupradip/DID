import 'package:flutter/material.dart';
import '../home/home_screen.dart';

class ProfileSetupScreen extends StatelessWidget {
  const ProfileSetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff101522),

      appBar: AppBar(
        backgroundColor: Colors.transparent,

        title: const Text("Complete Profile"),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          children: [
            const CircleAvatar(
              radius: 50,

              child: Icon(Icons.camera_alt, size: 35),
            ),

            const SizedBox(height: 30),

            field("Full Name", Icons.person),

            field("Bio", Icons.edit),

            field("GitHub Username", Icons.code),

            field("Skills", Icons.psychology),

            field("Interests", Icons.favorite),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,

              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const HomeScreen()),
                  );
                },

                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.greenAccent,
                ),

                child: const Text(
                  "Continue",
                  style: TextStyle(color: Colors.black),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget field(String hint, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),

      child: TextField(
        style: const TextStyle(color: Colors.white),

        decoration: InputDecoration(
          hintText: hint,

          prefixIcon: Icon(icon, color: Colors.white),

          filled: true,

          fillColor: const Color(0xff1B2235),

          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),

            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}
