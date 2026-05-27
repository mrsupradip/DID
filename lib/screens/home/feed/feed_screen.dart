import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FeedScreen extends StatelessWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff101522),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),

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
                      color: const Color(0xff1A2233),

                      borderRadius: BorderRadius.circular(12),
                    ),

                    child: const Row(
                      children: [
                        Text("For You", style: TextStyle(color: Colors.white)),

                        SizedBox(width: 6),

                        Icon(Icons.keyboard_arrow_down, color: Colors.white),
                      ],
                    ),
                  ),

                  const Icon(Icons.notifications_none, color: Colors.white),
                ],
              ),

              const SizedBox(height: 20),

              SizedBox(
                height: 40,

                child: ListView(
                  scrollDirection: Axis.horizontal,

                  children: [
                    chip("All"),
                    chip("Project"),
                    chip("Team"),
                    chip("Hackathon"),
                    chip("Jobs"),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              Expanded(
                child: ListView(
                  children: const [
                    FeedCard(),

                    SizedBox(height: 20),

                    FeedCard(),
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

      padding: const EdgeInsets.symmetric(horizontal: 18),

      decoration: BoxDecoration(
        color: const Color(0xff1A2233),

        borderRadius: BorderRadius.circular(12),
      ),

      child: Center(
        child: Text(text, style: const TextStyle(color: Colors.white)),
      ),
    );
  }
}

class FeedCard extends StatelessWidget {
  const FeedCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),

      decoration: BoxDecoration(
        color: const Color(0xff1A2233),

        borderRadius: BorderRadius.circular(25),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          const Row(
            children: [
              CircleAvatar(),

              SizedBox(width: 10),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  Text(
                    "Developer",

                    style: TextStyle(
                      color: Colors.white,

                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  Text("2h", style: TextStyle(color: Colors.grey)),
                ],
              ),
            ],
          ),

          const SizedBox(height: 15),

          Text(
            "Project update goes here 🚀",

            style: GoogleFonts.poppins(color: Colors.white),
          ),

          const SizedBox(height: 15),

          ClipRRect(
            borderRadius: BorderRadius.circular(20),

            child: Image.network("https://picsum.photos/500/300"),
          ),

          const SizedBox(height: 15),

          const Row(
            children: [
              Icon(Icons.favorite_border, color: Colors.white),

              SizedBox(width: 8),

              Text("120", style: TextStyle(color: Colors.white)),

              SizedBox(width: 25),

              Icon(Icons.chat_bubble_outline, color: Colors.white),

              SizedBox(width: 8),

              Text("15", style: TextStyle(color: Colors.white)),

              Spacer(),

              Icon(Icons.share, color: Colors.white),
            ],
          ),
        ],
      ),
    );
  }
}
