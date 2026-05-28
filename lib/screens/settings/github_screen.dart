import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/profile_service.dart';

class GithubScreen extends StatefulWidget {
  const GithubScreen({super.key});

  @override
  State<GithubScreen> createState() => _GithubScreenState();
}

class _GithubScreenState extends State<GithubScreen> {
  final TextEditingController usernameController = TextEditingController();
  bool connected = false;
  String githubUrl = 'https://github.com/login';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    usernameController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final profile = await ProfileService.loadProfile();
    if (!mounted) return;
    setState(() {
      connected = profile.githubConnected;
      githubUrl = profile.githubUrl;
      usernameController.text = profile.githubUsername;
    });
  }

  Future<void> _connect() async {
    final username = usernameController.text.trim();
    final url = username.isEmpty
        ? 'https://github.com/login'
        : 'https://github.com/$username';

    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not open GitHub')));
      return;
    }

    await ProfileService.setGithubConnection(
      connected: true,
      githubUsername: username.isEmpty ? 'github' : username,
      githubUrl: url,
    );

    if (!mounted) return;
    setState(() {
      connected = true;
      githubUrl = url;
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('GitHub connected')));
  }

  Future<void> _openLogin() async {
    await launchUrl(
      Uri.parse('https://github.com/login'),
      mode: LaunchMode.externalApplication,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff101522),
      appBar: AppBar(title: const Text('Connected GitHub')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: usernameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'GitHub username',
                hintStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: const Color(0xff1B2235),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _connect,
                child: Text(connected ? 'Reconnect GitHub' : 'Connect GitHub'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _openLogin,
                child: const Text('Open GitHub Login'),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Connected URL: $githubUrl',
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}
