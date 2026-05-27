import 'package:flutter/material.dart';
import '../profile/profile_screen.dart';
import '../../screens/auth/login_screen.dart';
import 'account_screen.dart';
import 'privacy_screen.dart';
import 'notification_screen.dart';
import 'github_screen.dart';
import 'theme_screen.dart';
import 'help_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

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
                "Settings",

                style: TextStyle(
                  color: Colors.white,

                  fontSize: 32,

                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 30),

              profileCard(),

              const SizedBox(height: 25),

              settingTile(Icons.person_outline, "Account", () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AccountScreen()),
                );
              }),

              settingTile(Icons.lock_outline, "Privacy", () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PrivacyScreen()),
                );
              }),

              settingTile(Icons.notifications_none, "Notifications", () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NotificationScreen()),
                );
              }),

              settingTile(Icons.code, "Connected GitHub", () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const GithubScreen()),
                );
              }),

              settingTile(Icons.dark_mode_outlined, "Theme", () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ThemeScreen()),
                );
              }),

              settingTile(Icons.help_outline, "Help Center", () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HelpScreen()),
                );
              }),

              const Spacer(),

              SizedBox(
                width: double.infinity,

                child: ElevatedButton(
                  onPressed: () {
                    // Navigate to login and clear history
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

                  child: const Text("Logout"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget profileCard() {
    return Builder(
      builder: (context) {
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(20),

            decoration: BoxDecoration(
              color: const Color(0xff1B2235),

              borderRadius: BorderRadius.circular(25),
            ),

            child: Row(
              children: [
                const CircleAvatar(radius: 30, child: Icon(Icons.person)),

                const SizedBox(width: 15),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: const [
                      Text(
                        "User Profile",

                        style: TextStyle(
                          color: Colors.white,

                          fontWeight: FontWeight.bold,

                          fontSize: 18,
                        ),
                      ),

                      SizedBox(height: 5),

                      Text(
                        "Profile info loads dynamically",

                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget settingTile(IconData icon, String title, VoidCallback? onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),

      decoration: BoxDecoration(
        color: const Color(0xff1B2235),

        borderRadius: BorderRadius.circular(20),
      ),

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
    );
  }
}
