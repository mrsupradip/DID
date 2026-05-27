import 'package:flutter/material.dart';

class TeamMatchScreen extends StatelessWidget {
  const TeamMatchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff101522),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              const Text(
                "Find Your Team",

                style: TextStyle(
                  color: Colors.white,

                  fontSize: 32,

                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

              TextField(
                style: const TextStyle(color: Colors.white),

                decoration: InputDecoration(
                  hintText: "Search skills...",

                  hintStyle: const TextStyle(color: Colors.grey),

                  prefixIcon: const Icon(Icons.search, color: Colors.white),

                  filled: true,

                  fillColor: const Color(0xff1B2235),

                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),

                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 25),

              Expanded(
                child: ListView(
                  children: const [
                    TeamCard(),

                    SizedBox(height: 15),

                    TeamCard(),

                    SizedBox(height: 15),

                    TeamCard(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TeamCard extends StatelessWidget {
  const TeamCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: const Color(0xff1B2235),

        borderRadius: BorderRadius.circular(25),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),

                decoration: BoxDecoration(
                  color: Colors.greenAccent,

                  borderRadius: BorderRadius.circular(15),
                ),

                child: const Icon(Icons.groups, color: Colors.black),
              ),

              const Spacer(),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),

                decoration: BoxDecoration(
                  color: Colors.black,

                  borderRadius: BorderRadius.circular(30),
                ),

                child: const Text(
                  "Open",

                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          const Text(
            "Project title loads dynamically",

            style: TextStyle(
              color: Colors.white,

              fontSize: 18,

              fontWeight: FontWeight.bold,
            ),
          ),

          SizedBox(height: 10),

          Text(
            "Required skills appear from backend",

            style: TextStyle(color: Colors.grey),
          ),

          SizedBox(height: 20),

          SizedBox(
            width: double.infinity,

            child: ElevatedButton(
              onPressed: () {},

              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.greenAccent,
              ),

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
