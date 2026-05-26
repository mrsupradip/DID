import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:did/screens/home/feed/feed_screen.dart';
import '../team_match/team_match_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int selectedIndex = 0;

  final Color green = const Color(0xff63FF9B);

  @override
  Widget build(BuildContext context) {
    final pages = [
      const HomePage(),

      const FeedScreen(),

      const Center(
        child: Text("Team Match", style: TextStyle(color: Colors.white)),
      ),

      const Center(
        child: Text("Profile", style: TextStyle(color: Colors.white)),
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xff1B1E2B),

      body: pages[selectedIndex],

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,

        onTap: (index) {
          setState(() {
            selectedIndex = index;
          });
        },

        backgroundColor: Colors.black,

        type: BottomNavigationBarType.fixed,

        selectedItemColor: green,

        unselectedItemColor: Colors.white54,

        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.home), label: ""),

          BottomNavigationBarItem(
            icon: Container(
              padding: const EdgeInsets.all(10),

              decoration: BoxDecoration(color: green, shape: BoxShape.circle),

              child: const Icon(Icons.dynamic_feed, color: Colors.black),
            ),
            label: "",
          ),

          const BottomNavigationBarItem(icon: Icon(Icons.groups), label: ""),

          const BottomNavigationBarItem(icon: Icon(Icons.person), label: ""),
        ],
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    Color green = const Color(0xff63FF9B);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,

              children: [
                const Icon(Icons.menu, color: Colors.white, size: 30),

                CircleAvatar(
                  backgroundColor: green,

                  child: const Icon(Icons.person, color: Colors.black),
                ),
              ],
            ),

            const SizedBox(height: 30),

            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: "Your Favorite\n",

                    style: GoogleFonts.poppins(
                      color: Colors.white,

                      fontWeight: FontWeight.bold,

                      fontSize: 34,
                    ),
                  ),

                  TextSpan(
                    text: "Developers",

                    style: GoogleFonts.poppins(
                      color: green,

                      fontWeight: FontWeight.bold,

                      fontSize: 34,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            SizedBox(
              height: 40,

              child: ListView(
                scrollDirection: Axis.horizontal,

                children: [
                  chip("All", true),

                  chip("Flutter", false),

                  chip("Backend", false),

                  chip("AI", false),

                  chip("Projects", false),
                ],
              ),
            ),

            const SizedBox(height: 25),

            Expanded(
              child: ListView(
                children: [
                  card("D!D Team Finder", "Find teammates instantly", green),

                  const SizedBox(height: 20),

                  card("Flutter Hub", "Need mobile developers", green),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget chip(String text, bool active) {
    return Container(
      margin: const EdgeInsets.only(right: 10),

      padding: const EdgeInsets.symmetric(horizontal: 20),

      decoration: BoxDecoration(
        color: active ? const Color(0xff63FF9B) : const Color(0xff2B3040),

        borderRadius: BorderRadius.circular(25),
      ),

      child: Center(
        child: Text(
          text,
          style: TextStyle(color: active ? Colors.black : Colors.white),
        ),
      ),
    );
  }

  Widget card(String title, String sub, Color green) {
    return Container(
      height: 140,

      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        color: const Color(0xff0F121A),

        borderRadius: BorderRadius.circular(25),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),

            decoration: BoxDecoration(
              color: green,

              borderRadius: BorderRadius.circular(20),
            ),

            child: const Text("LIVE", style: TextStyle(color: Colors.black)),
          ),

          const Spacer(),

          Text(
            title,

            style: const TextStyle(
              color: Colors.white,

              fontSize: 18,

              fontWeight: FontWeight.bold,
            ),
          ),

          Text(sub, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
