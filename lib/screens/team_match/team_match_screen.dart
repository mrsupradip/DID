import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TeamMatchScreen extends StatelessWidget {
  const TeamMatchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Color green = const Color(0xff63FF9B);

    return Scaffold(
      backgroundColor: const Color(0xff1B1E2B),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Text(
                "Find Your\nDream Team",

                style: GoogleFonts.poppins(
                  color: Colors.white,

                  fontSize: 34,

                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 25),

              TextField(
                style: const TextStyle(color: Colors.white),

                decoration: InputDecoration(
                  hintText: "Search skills...",

                  hintStyle: const TextStyle(color: Colors.grey),

                  prefixIcon: const Icon(Icons.search, color: Colors.white),

                  filled: true,

                  fillColor: const Color(0xff0F121A),

                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),

                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 25),

              Expanded(
                child: ListView(
                  children: [
                    teamCard(
                      "Flutter Project",
                      "Need Flutter + Firebase dev",

                      "3/5 members",

                      green,
                    ),

                    const SizedBox(height: 20),

                    teamCard(
                      "AI Hackathon",
                      "Need backend engineer",

                      "2/6 members",

                      green,
                    ),

                    const SizedBox(height: 20),

                    teamCard(
                      "D!D Startup",
                      "Need UI designer",

                      "1/4 members",

                      green,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget teamCard(String title, String sub, String members, Color green) {
    return Container(
      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        color: const Color(0xff0F121A),

        borderRadius: BorderRadius.circular(25),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: green,

                child: const Icon(Icons.groups, color: Colors.black),
              ),

              const Spacer(),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,

                  vertical: 6,
                ),

                decoration: BoxDecoration(
                  color: green,

                  borderRadius: BorderRadius.circular(20),
                ),

                child: Text(
                  members,

                  style: const TextStyle(color: Colors.black),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          Text(
            title,

            style: const TextStyle(
              color: Colors.white,

              fontWeight: FontWeight.bold,

              fontSize: 18,
            ),
          ),

          const SizedBox(height: 8),

          Text(sub, style: const TextStyle(color: Colors.grey)),

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,

            child: ElevatedButton(
              onPressed: () {},

              style: ElevatedButton.styleFrom(backgroundColor: green),

              child: const Text(
                "Join Team",
                style: TextStyle(color: Colors.black),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
