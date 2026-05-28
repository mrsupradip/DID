import 'package:flutter/material.dart';

import '../../services/profile_service.dart';

class PrivacyScreen extends StatefulWidget {
  const PrivacyScreen({super.key});

  @override
  State<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends State<PrivacyScreen> {
  Future<ProfileData>? _profileFuture;
  bool _privateAccount = true;
  bool _showSkillsPublic = false;

  @override
  void initState() {
    super.initState();
    _profileFuture = ProfileService.loadProfile();
    _load();
  }

  Future<void> _load() async {
    final profile = await ProfileService.loadProfile();
    if (!mounted) return;
    setState(() {
      _privateAccount = profile.privateAccount;
      _showSkillsPublic = profile.showSkillsPublicly;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff101522),
      appBar: AppBar(title: const Text('Privacy')),
      body: FutureBuilder<ProfileData>(
        future: _profileFuture,
        builder: (context, snapshot) {
          return ListView(
            children: [
              SwitchListTile(
                value: _privateAccount,
                onChanged: (v) async {
                  setState(() => _privateAccount = v);
                  await ProfileService.setPrivateAccount(v);
                },
                title: const Text(
                  'Private Account',
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: const Text(
                  'Only approved people can view your profile.',
                  style: TextStyle(color: Colors.white54),
                ),
              ),
              SwitchListTile(
                value: _showSkillsPublic,
                onChanged: (v) async {
                  setState(() => _showSkillsPublic = v);
                  await ProfileService.setShowSkillsPublicly(v);
                },
                title: const Text(
                  'Show Skills Publicly',
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: const Text(
                  'Show your skills on the profile header and team cards.',
                  style: TextStyle(color: Colors.white54),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
