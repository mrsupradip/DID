import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

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
              Text(
                "Messages",

                style: GoogleFonts.poppins(
                  color: Colors.white,

                  fontSize: 32,

                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

              TextField(
                style: const TextStyle(color: Colors.white),

                decoration: InputDecoration(
                  hintText: "Search chats",

                  hintStyle: const TextStyle(color: Colors.grey),

                  prefixIcon: const Icon(Icons.search, color: Colors.white),

                  filled: true,

                  fillColor: const Color(0xff1A2233),

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
                    ChatTile(),

                    ChatTile(),

                    ChatTile(),

                    ChatTile(),
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

class ChatTile extends StatelessWidget {
  const ChatTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),

      padding: const EdgeInsets.all(15),

      decoration: BoxDecoration(
        color: const Color(0xff1A2233),

        borderRadius: BorderRadius.circular(20),
      ),

      child: const Row(
        children: [
          CircleAvatar(radius: 25),

          SizedBox(width: 15),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  "Developer",

                  style: TextStyle(
                    color: Colors.white,

                    fontWeight: FontWeight.bold,
                  ),
                ),

                SizedBox(height: 5),

                Text(
                  "Last message appears here...",

                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),

          Text("2m", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
