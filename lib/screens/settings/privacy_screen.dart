import 'package:flutter/material.dart';

class PrivacyScreen extends StatefulWidget {
  const PrivacyScreen({super.key});

  @override
  State<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends State<PrivacyScreen> {
  bool _privateAccount = true;
  bool _showSkillsPublic = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff101522),

      appBar: AppBar(title: const Text("Privacy")),

      body: Column(
        children: [
          SwitchListTile(
            value: _privateAccount,
            onChanged: (v) => setState(() => _privateAccount = v),
            title: const Text(
              "Private Account",
              style: TextStyle(color: Colors.white),
            ),
          ),

          SwitchListTile(
            value: _showSkillsPublic,
            onChanged: (v) => setState(() => _showSkillsPublic = v),
            title: const Text(
              "Show Skills Publicly",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
