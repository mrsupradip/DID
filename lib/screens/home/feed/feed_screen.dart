import 'package:flutter/material.dart';

class FeedScreen extends StatelessWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(15),

          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,

                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 10,
                    ),

                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(10),
                    ),

                    child: const Row(
                      children: [
                        Text("For You", style: TextStyle(color: Colors.white)),

                        Icon(Icons.keyboard_arrow_down, color: Colors.white),
                      ],
                    ),
                  ),

                  const Icon(Icons.notifications_none, color: Colors.white),
                ],
              ),

              const SizedBox(height: 20),

              SizedBox(
                height: 45,

                child: ListView(
                  scrollDirection: Axis.horizontal,

                  children: [
                    chip("All"),
                    chip("Photo"),
                    chip("Video"),
                    chip("Sound"),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              Expanded(
                child: ListView(
                  children: [
                    postCard("Supradip", "Started building D!D 🚀"),

                    const SizedBox(height: 20),

                    postCard("Developer", "Need Flutter team members"),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget chip(String text) {
    return Container(
      margin: const EdgeInsets.only(right: 10),

      padding: const EdgeInsets.symmetric(horizontal: 20),

      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white24),
      ),

      child: Center(
        child: Text(text, style: const TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget postCard(String user, String caption) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xff111111),
        borderRadius: BorderRadius.circular(25),
      ),

      padding: const EdgeInsets.all(15),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Text(
            user,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          Text(caption, style: const TextStyle(color: Colors.white70)),

          const SizedBox(height: 15),

          ClipRRect(
            borderRadius: BorderRadius.circular(20),

            child: Image.network("https://picsum.photos/500/300"),
          ),
        ],
      ),
    );
  }
}
