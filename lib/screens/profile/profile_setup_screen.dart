import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/firestore_service.dart';
import '../home/home_screen.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final TextEditingController nameController = TextEditingController();

  final TextEditingController bioController = TextEditingController();

  final TextEditingController githubController = TextEditingController();

  final TextEditingController skillsController = TextEditingController();

  final FirestoreService firestoreService = FirestoreService();

  bool loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff101522),

      appBar: AppBar(
        backgroundColor: Colors.transparent,

        elevation: 0,

        title: const Text("Complete Profile"),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          children: [
            const SizedBox(height: 20),

            const CircleAvatar(
              radius: 55,

              backgroundColor: Color(0xff1B2235),

              child: Icon(Icons.person, size: 55, color: Colors.white),
            ),

            const SizedBox(height: 35),

            field(
              controller: nameController,

              hint: "Full Name",

              icon: Icons.person,
            ),

            field(controller: bioController, hint: "Bio", icon: Icons.edit),

            field(
              controller: githubController,

              hint: "GitHub Username",

              icon: Icons.code,
            ),

            field(
              controller: skillsController,

              hint: "Skills (comma separated)",

              icon: Icons.psychology,
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,

              child: ElevatedButton(
                onPressed: () async {
                  setState(() {
                    loading = true;
                  });

                  final user = FirebaseAuth.instance.currentUser;

                  if (user != null) {
                    await firestoreService.saveUser(
                      uid: user.uid,

                      name: nameController.text,

                      bio: bioController.text,

                      github: githubController.text,

                      skills: skillsController.text.split(","),
                    );

                    Navigator.pushReplacement(
                      context,

                      MaterialPageRoute(builder: (_) => const HomeScreen()),
                    );
                  }

                  setState(() {
                    loading = false;
                  });
                },

                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.greenAccent,

                  padding: const EdgeInsets.all(18),
                ),

                child: loading
                    ? const CircularProgressIndicator(color: Colors.black)
                    : const Text(
                        "Continue",

                        style: TextStyle(
                          color: Colors.black,

                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget field({
    required TextEditingController controller,

    required String hint,

    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),

      child: TextField(
        controller: controller,

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
