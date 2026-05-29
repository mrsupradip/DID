import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';

import '../../services/account_deletion_service.dart';
import '../../services/firestore_service.dart';
import '../../services/profile_service.dart';
import '../../services/session_service.dart';
import '../../utils/image_source.dart';
import '../auth/login_screen.dart';
import 'terms_conditions_screen.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final FirestoreService firestoreService = FirestoreService();
  final LocalAuthentication _auth = LocalAuthentication();
  Future<ProfileData>? _profileFuture;
  bool _biometricEnabled = false;
  bool _biometricSupported = false;

  @override
  void initState() {
    super.initState();
    _profileFuture = ProfileService.loadProfile();
    _loadBiometricState();
  }

  void _reload() {
    setState(() {
      _profileFuture = ProfileService.loadProfile();
    });
  }

  Future<void> _loadBiometricState() async {
    final supported = await _auth.isDeviceSupported();
    final canCheck = await _auth.canCheckBiometrics;
    final enabled = await SessionService.isBiometricEnabled();

    if (!mounted) return;
    setState(() {
      _biometricSupported = supported && canCheck;
      _biometricEnabled = enabled;
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

  Future<void> _changePassword() async {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final messenger = ScaffoldMessenger.of(context);

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xff101522),
        title: const Text(
          'Change Password',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentPasswordController,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(hintText: 'Current password'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newPasswordController,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(hintText: 'New password'),
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
                'current': currentPasswordController.text.trim(),
                'new': newPasswordController.text.trim(),
              });
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    currentPasswordController.dispose();
    newPasswordController.dispose();

    if (result == null) return;
    final currentPassword = result['current'] ?? '';
    final newPassword = result['new'] ?? '';
    if (currentPassword.isEmpty || newPassword.length < 6) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Enter a valid new password')),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email;
    if (user == null || email == null) return;

    try {
      final credential = EmailAuthProvider.credential(
        email: email,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Password updated')));
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Failed to update password')),
      );
    }
  }

  Future<void> _deleteAccount() async {
    final passwordController = TextEditingController();
    final navigator = Navigator.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xff101522),
        title: const Text(
          'Delete Account',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'This removes your account, posts, stories, team memberships, saved post links, notifications, friend requests, and chat messages.',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passwordController,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Password to confirm',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) {
      passwordController.dispose();
      return;
    }

    final password = passwordController.text.trim();
    passwordController.dispose();

    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email;
    if (user == null || email == null || password.isEmpty) return;

    try {
      final credential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);

      final uid = user.uid;
      await AccountDeletionService().deleteAccountCompletely(uid: uid);
      await SessionService.clearLastActive();
      await SessionService.clearLastEmail();

      if (!mounted) return;
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Failed to delete account')),
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
              ListTile(
                leading: const Icon(Icons.lock_reset, color: Colors.white),
                title: const Text(
                  'Change Password',
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: const Text(
                  'Update your login password.',
                  style: TextStyle(color: Colors.white54),
                ),
                onTap: _changePassword,
              ),
              ListTile(
                leading: const Icon(Icons.description, color: Colors.white),
                title: const Text(
                  'Terms & Conditions',
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: const Text(
                  'View terms and privacy',
                  style: TextStyle(color: Colors.white54),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const TermsConditionsScreen(),
                    ),
                  );
                },
              ),
              SwitchListTile(
                value: _biometricEnabled,
                onChanged: !_biometricSupported
                    ? null
                    : (value) async {
                        await SessionService.setBiometricEnabled(value);
                        if (!mounted) return;
                        setState(() => _biometricEnabled = value);
                      },
                secondary: const Icon(Icons.fingerprint, color: Colors.white),
                title: const Text(
                  'Fingerprint Unlock',
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  _biometricSupported
                      ? 'Use fingerprint on app unlock screen.'
                      : 'Fingerprint not available on this device.',
                  style: const TextStyle(color: Colors.white54),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Email changes require your current password for verification.',
                style: TextStyle(color: Colors.white54),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _deleteAccount,
                icon: const Icon(Icons.delete_forever),
                label: const Text('Delete Account'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
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
            backgroundImage: resolveImageProvider(profile.profileImagePath),
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
