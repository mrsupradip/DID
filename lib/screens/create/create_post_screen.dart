import 'package:flutter/material.dart';

class CreatePostScreen extends StatelessWidget {
  const CreatePostScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff101522),

      appBar: AppBar(
        backgroundColor: Colors.transparent,

        title: const Text("Create Post"),
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(15),

              decoration: BoxDecoration(
                color: const Color(0xff1B2235),

                borderRadius: BorderRadius.circular(20),
              ),

              child: const TextField(
                maxLines: 6,

                style: TextStyle(color: Colors.white),

                decoration: InputDecoration(
                  border: InputBorder.none,

                  hintText: "Share project updates...",

                  hintStyle: TextStyle(color: Colors.grey),
                ),
              ),
            ),

            const SizedBox(height: 20),

            Row(
              children: [
                action(Icons.image, "Photo"),

                const SizedBox(width: 15),

                action(Icons.group, "Team"),

                const SizedBox(width: 15),

                action(Icons.code, "Project"),
              ],
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,

              child: ElevatedButton(
                onPressed: () {},

                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.greenAccent,

                  padding: const EdgeInsets.all(15),
                ),

                child: const Text(
                  "Post",
                  style: TextStyle(color: Colors.black),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget action(IconData icon, String text) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(15),

        decoration: BoxDecoration(
          color: const Color(0xff1B2235),

          borderRadius: BorderRadius.circular(15),
        ),

        child: Column(
          children: [
            Icon(icon, color: Colors.white),

            const SizedBox(height: 8),

            Text(text, style: const TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }
}
