import 'package:flutter/material.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  bool _messages = true;
  bool _teamRequests = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff101522),

      appBar: AppBar(title: const Text("Notifications")),

      body: Column(
        children: [
          SwitchListTile(
            value: _messages,
            onChanged: (v) => setState(() => _messages = v),
            title: const Text(
              "Messages",
              style: TextStyle(color: Colors.white),
            ),
          ),

          SwitchListTile(
            value: _teamRequests,
            onChanged: (v) => setState(() => _teamRequests = v),
            title: const Text(
              "Team Requests",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
