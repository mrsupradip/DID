import 'package:flutter/material.dart';
import '../profile/profile_screen.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  void _showPending(BuildContext context, String feature) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$feature coming soon')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff101522),

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text("Account"),
      ),

      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.person, color: Colors.white),
            title: const Text(
              "Edit Profile",
              style: TextStyle(color: Colors.white),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
          ),

          ListTile(
            leading: const Icon(Icons.badge, color: Colors.white),
            title: const Text(
              "Change Username",
              style: TextStyle(color: Colors.white),
            ),
            onTap: () => _showPending(context, 'Change Username'),
          ),

          ListTile(
            leading: const Icon(Icons.email, color: Colors.white),
            title: const Text(
              "Change Email",
              style: TextStyle(color: Colors.white),
            ),
            onTap: () => _showPending(context, 'Change Email'),
          ),
        ],
      ),
    );
  }
}
