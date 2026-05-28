import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'feed/feed_screen.dart';
import '../chat/chat_screen.dart';
import '../profile/profile_screen.dart';
import '../feed/create_post_screen.dart';
import '../settings/settings_screen.dart';
import '../team_match/team_match_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int selectedIndex = 0;
  final pages = const [
    HomePage(),
    FeedScreen(),
    CreatePostScreen(),
    ChatScreen(),
    TeamMatchScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff101522),

      body: pages[selectedIndex],

      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.greenAccent,

        child: const Icon(Icons.add, color: Colors.black),

        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreatePostScreen()),
          );
        },
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,

        onTap: (index) {
          setState(() {
            selectedIndex = index;
          });
        },

        type: BottomNavigationBarType.fixed,

        backgroundColor: Colors.black,

        selectedItemColor: Colors.greenAccent,

        unselectedItemColor: Colors.white54,

        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: ""),

          BottomNavigationBarItem(icon: Icon(Icons.dynamic_feed), label: ""),

          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle, size: 35),

            label: "",
          ),

          BottomNavigationBarItem(icon: Icon(Icons.chat), label: ""),

          BottomNavigationBarItem(icon: Icon(Icons.person), label: ""),
        ],
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            /// TOP BAR
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,

              children: [
                IconButton(
                  icon: const Icon(Icons.menu, color: Colors.white),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    );
                  },
                ),

                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ProfileScreen()),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(2),

                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(100),

                      border: Border.all(color: Colors.greenAccent),
                    ),

                    child: const CircleAvatar(
                      radius: 22,

                      child: Icon(Icons.person),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            const Text(
              "Welcome Back 👋",

              style: TextStyle(color: Colors.grey, fontSize: 18),
            ),

            const SizedBox(height: 10),

            const Text(
              "Ready To Build?",

              style: TextStyle(
                color: Colors.white,

                fontSize: 34,

                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 30),

            /// BANNER
            Container(
              padding: const EdgeInsets.all(20),

              decoration: BoxDecoration(
                color: Colors.greenAccent,

                borderRadius: BorderRadius.circular(30),
              ),

              child: const Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [
                        Text(
                          "Build Together",

                          style: TextStyle(
                            color: Colors.black,

                            fontSize: 22,

                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        SizedBox(height: 8),

                        Text(
                          "Connect with developers and create projects",

                          style: TextStyle(color: Colors.black87),
                        ),
                      ],
                    ),
                  ),

                  Icon(Icons.rocket_launch, color: Colors.black, size: 45),
                ],
              ),
            ),

            const SizedBox(height: 35),

            const Text(
              "Explore",

              style: TextStyle(
                color: Colors.white,

                fontWeight: FontWeight.bold,

                fontSize: 24,
              ),
            ),

            const SizedBox(height: 15),

            Wrap(
              spacing: 10,

              runSpacing: 10,

              children: [
                chip("Flutter"),

                chip("AI"),

                chip("Backend"),

                chip("Open Source"),

                chip("Hackathon"),

                chip("Projects"),
              ],
            ),

            const SizedBox(height: 35),

            const Text(
              "Live Feed",

              style: TextStyle(
                color: Colors.white,

                fontWeight: FontWeight.bold,

                fontSize: 24,
              ),
            ),

            const SizedBox(height: 20),

            const FeedPreview(),

            const SizedBox(height: 15),

            const FeedPreview(),
          ],
        ),
      ),
    );
  }

  static Widget chip(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),

      decoration: BoxDecoration(
        color: const Color(0xff1B2235),

        borderRadius: BorderRadius.circular(15),
      ),

      child: Text(title, style: const TextStyle(color: Colors.white)),
    );
  }

  static Widget card() {
    return Container(
      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        color: const Color(0xff1B2235),

        borderRadius: BorderRadius.circular(25),
      ),

      child: const Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  "Discover developer projects",

                  style: TextStyle(
                    color: Colors.white,

                    fontWeight: FontWeight.bold,
                  ),
                ),

                SizedBox(height: 8),

                Text(
                  "Find teammates and collaborate",

                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),

          Icon(Icons.arrow_forward, color: Colors.white),
        ],
      ),
    );
  }
}

class FeedPreview extends StatelessWidget {
  const FeedPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .orderBy('createdAt', descending: true)
          .limit(1)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return HomePage.card();
        }

        final post = snapshot.data!.docs.first.data();
        final caption = (post['caption'] ?? '').toString();
        final attachmentName = post['attachmentName'];

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xff1B2235),
            borderRadius: BorderRadius.circular(25),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'New post from your network',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                caption.isEmpty ? 'Shared something new' : caption,
                style: const TextStyle(color: Colors.grey),
              ),
              if (attachmentName != null) ...[
                const SizedBox(height: 10),
                Text(
                  attachmentName.toString(),
                  style: const TextStyle(color: Colors.greenAccent),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
