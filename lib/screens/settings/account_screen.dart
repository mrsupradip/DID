import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/firestore_service.dart';
import '../../services/profile_service.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final FirestoreService firestoreService = FirestoreService();
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

  Future<void> _changeUsername(ProfileData profile) async {
    final controller = TextEditingController(text: profile.displayName);
    final newName = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xff101522),
        title: const Text(
          'Change Username',
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(hintText: 'New username'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (newName == null || newName.isEmpty) return;

    await ProfileService.updateProfile(
      (current) => current.copyWith(displayName: newName),
    );

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await firestoreService.updateUser(uid: user.uid, data: {'name': newName});
    }

    _reload();
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Username updated')));
  }

  Future<void> _changeEmail(ProfileData profile) async {
    final emailController = TextEditingController(text: profile.email);
    final passwordController = TextEditingController();

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xff101522),
        title: const Text(
          'Change Email',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: emailController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(hintText: 'New email'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passwordController,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(hintText: 'Current password'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext, {
                'email': emailController.text.trim(),
                'password': passwordController.text,
              });
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == null) return;
    final newEmail = result['email']?.trim() ?? '';
    final password = result['password'] ?? '';
    if (newEmail.isEmpty || password.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    final currentEmail = user?.email;
    if (user == null || currentEmail == null) return;

    final credential = EmailAuthProvider.credential(
      email: currentEmail,
      password: password,
    );

    try {
      await user.reauthenticateWithCredential(credential);
      await user.verifyBeforeUpdateEmail(newEmail);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Verification email sent. Open the link to confirm the change.',
          ),
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Failed to update email')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff101522),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Account'),
      ),
      body: FutureBuilder<ProfileData>(
        future: _profileFuture,
        builder: (context, snapshot) {
          final profile = snapshot.data ?? ProfileData.defaultData();
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _header(profile),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.person, color: Colors.white),
                title: const Text(
                  'Change Username',
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  profile.displayName,
                  style: const TextStyle(color: Colors.white54),
                ),
                onTap: () => _changeUsername(profile),
              ),
              ListTile(
                leading: const Icon(Icons.email, color: Colors.white),
                title: const Text(
                  'Change Email',
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  profile.email,
                  style: const TextStyle(color: Colors.white54),
                ),
                onTap: () => _changeEmail(profile),
              ),
              const SizedBox(height: 12),
              const Text(
                'Email changes require your current password for verification.',
                style: TextStyle(color: Colors.white54),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _header(ProfileData profile) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xff1B2235),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.greenAccent,
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
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  profile.email,
                  style: const TextStyle(color: Colors.white54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
