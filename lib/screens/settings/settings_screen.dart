import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/profile_service.dart';
import '../../services/session_service.dart';
import '../auth/login_screen.dart';
import '../profile/edit_profile_screen.dart';
import 'account_screen.dart';
import 'github_screen.dart';
import 'help_screen.dart';
import 'notification_screen.dart';
import 'privacy_screen.dart';
import 'theme_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Future<ProfileData>? _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = ProfileService.loadProfile();
  }

  void _reload() {
    setState(() {
      _profileFuture = ProfileService.loadProfile();
    });
  }

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
              const Text(
                'Settings',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              FutureBuilder<ProfileData>(
                future: _profileFuture,
                builder: (context, snapshot) {
                  final profile = snapshot.data ?? ProfileData.defaultData();
                  return GestureDetector(
                    onTap: () async {
                      final changed = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const EditProfileScreen(),
                        ),
                      );
                      if (changed == true) _reload();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xff1B2235),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: Colors.greenAccent,
                            backgroundImage: profile.profileImagePath.isEmpty
                                ? null
                                : FileImage(File(profile.profileImagePath)),
                            child: profile.profileImagePath.isEmpty
                                ? const Icon(Icons.person, color: Colors.black)
                                : null,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  profile.displayName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  profile.bio,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.edit, color: Colors.greenAccent),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView(
                  children: [
                    settingTile(Icons.person_outline, 'Account', () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AccountScreen(),
                        ),
                      );
                    }),
                    settingTile(Icons.lock_outline, 'Privacy', () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PrivacyScreen(),
                        ),
                      );
                    }),
                    settingTile(Icons.notifications_none, 'Notifications', () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const NotificationScreen(),
                        ),
                      );
                    }),
                    settingTile(Icons.code, 'Connected GitHub', () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const GithubScreen()),
                      );
                    }),
                    settingTile(Icons.dark_mode_outlined, 'Theme', () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ThemeScreen()),
                      );
                    }),
                    settingTile(Icons.help_outline, 'Help Center', () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const HelpScreen()),
                      );
                    }),
                  ],
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();
                    await SessionService.clearLastActive();
                    await SessionService.clearLastEmail();
                    if (!context.mounted) return;
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.all(15),
                  ),
                  child: const Text('Logout'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget settingTile(IconData icon, String title, VoidCallback? onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: const Color(0xff1B2235),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          leading: Icon(icon, color: Colors.white),
          title: Text(title, style: const TextStyle(color: Colors.white)),
          trailing: const Icon(
            Icons.arrow_forward_ios,
            color: Colors.grey,
            size: 15,
          ),
          onTap: onTap,
        ),
      ),
    );
  }
}
