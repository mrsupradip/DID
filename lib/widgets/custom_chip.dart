import 'package:flutter/material.dart';

class CustomChip extends StatelessWidget {
  final String title;

  const CustomChip({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),

      decoration: BoxDecoration(
        color: const Color(0xff1B2235),

        borderRadius: BorderRadius.circular(25),
      ),

      child: Text(title, style: const TextStyle(color: Colors.white)),
    );
  }
}
