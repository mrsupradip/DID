import 'package:flutter/material.dart';

import '../../services/profile_service.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  bool _messages = true;
  bool _teamRequests = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final profile = await ProfileService.loadProfile();
    if (!mounted) return;
    setState(() {
      _messages = profile.messagesNotifications;
      _teamRequests = profile.teamRequestsNotifications;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff101522),
      appBar: AppBar(title: const Text('Notifications')),
      body: ListView(
        children: [
          SwitchListTile(
            value: _messages,
            onChanged: (v) async {
              setState(() => _messages = v);
              await ProfileService.setMessagesNotifications(v);
            },
            title: const Text(
              'Messages',
              style: TextStyle(color: Colors.white),
            ),
            subtitle: const Text(
              'Alerts when someone sends you a direct message.',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          SwitchListTile(
            value: _teamRequests,
            onChanged: (v) async {
              setState(() => _teamRequests = v);
              await ProfileService.setTeamRequestsNotifications(v);
            },
            title: const Text(
              'Team Requests',
              style: TextStyle(color: Colors.white),
            ),
            subtitle: const Text(
              'Alerts when someone joins or requests your team.',
              style: TextStyle(color: Colors.white54),
            ),
          ),
        ],
      ),
    );
  }
}
