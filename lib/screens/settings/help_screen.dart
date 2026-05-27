import 'package:flutter/material.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff101522),

      appBar: AppBar(title: const Text("Help Center")),

      body: const Center(
        child: Text(
          "FAQ and support appear here",
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
