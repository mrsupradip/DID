import 'package:flutter/material.dart';

import '../home/home_screen.dart' show LiveFeedSection;

class FeedScreen extends StatelessWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff101522),
      appBar: AppBar(
        backgroundColor: const Color(0xff101522),
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'Live Feed',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: const SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(18, 8, 18, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Latest posts',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              SizedBox(height: 14),
              LiveFeedSection(),
            ],
          ),
        ),
      ),
    );
  }
}
