import 'package:flutter/material.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sections = [
      'You must meet the minimum legal age in your region to use this app.',
      'Use accurate information and do not impersonate other people or organizations.',
      'Do not post spam, harassment, abuse, hate content, or illegal material.',
      'You are responsible for the content you post, comment, share, and upload.',
      'We may remove content or suspend accounts that violate community rules or security requirements.',
      'Do not attempt to scrape, reverse engineer, or abuse the app, backend, or other users.',
      'Do not attempt to access or share private data, credentials, or payment details.',
      'Report security issues to support instead of exploiting them.',
      'Repeated violations may result in permanent account removal.',
      'By creating an account, you consent to authentication, profile storage, and device-based security features such as fingerprint unlock.',
    ];

    return Scaffold(
      backgroundColor: const Color(0xff101522),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Terms & Conditions'),
      ),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            20 + MediaQuery.of(context).padding.bottom + 48,
          ),
          children: [
          const Text(
            'D!D Community Terms',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'These terms apply to every account and all posted content.',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 20),
          ...sections.map(
            (section) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xff1B2235),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                section,
                style: const TextStyle(color: Colors.white70, height: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Privacy & Security',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'We store data in Firebase services. Deleting your account removes your authentication record and user document. Some content may remain in backups. For full removal, contact support.',
            style: TextStyle(color: Colors.white70, height: 1.4),
          ),
          ],
        ),
      ),
    );
  }
}
