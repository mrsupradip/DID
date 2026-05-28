import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/profile_service.dart';
import '../../widgets/custom_chip.dart';
import '../settings/settings_screen.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
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

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not open $url')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff101522),
      body: FutureBuilder<ProfileData>(
        future: _profileFuture,
        builder: (context, snapshot) {
          final profile = snapshot.data ?? ProfileData.defaultData();

          return SingleChildScrollView(
            child: Column(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      height: 260,
                      decoration: BoxDecoration(
                        image: profile.headerImagePath.isNotEmpty
                            ? DecorationImage(
                                image: FileImage(File(profile.headerImagePath)),
                                fit: BoxFit.cover,
                              )
                            : null,
                        gradient: profile.headerImagePath.isEmpty
                            ? const LinearGradient(
                                colors: [Color(0xff34d399), Color(0xff0F172A)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                      ),
                    ),
                    Positioned(
                      top: 50,
                      left: 20,
                      child: _roundIconButton(
                        Icons.settings,
                        onTap: () async {
                          final changed = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SettingsScreen(),
                            ),
                          );
                          if (changed == true) _reload();
                        },
                      ),
                    ),
                    Positioned(
                      top: 50,
                      right: 20,
                      child: _roundIconButton(
                        Icons.edit,
                        onTap: () async {
                          final changed = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const EditProfileScreen(),
                            ),
                          );
                          if (changed == true) _reload();
                        },
                      ),
                    ),
                    Positioned(
                      bottom: -56,
                      left: 0,
                      right: 0,
                      child: CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.greenAccent,
                        child: CircleAvatar(
                          radius: 56,
                          backgroundColor: const Color(0xff111827),
                          backgroundImage: profile.profileImagePath.isNotEmpty
                              ? FileImage(File(profile.profileImagePath))
                              : null,
                          child: profile.profileImagePath.isEmpty
                              ? const Icon(
                                  Icons.person,
                                  size: 55,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 70),
                Text(
                  profile.displayName,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    profile.bio,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(color: Colors.white70),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: () => _openUrl(profile.githubUrl),
                  icon: const Icon(
                    Icons.open_in_browser,
                    color: Colors.greenAccent,
                  ),
                  label: const Text(
                    'Open GitHub',
                    style: TextStyle(color: Colors.greenAccent),
                  ),
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: profile.skills
                      .map((skill) => CustomChip(title: skill))
                      .toList(),
                ),
                const SizedBox(height: 30),
                _sectionHeader('Projects'),
                const SizedBox(height: 10),
                ...profile.projects.map(
                  (project) => _ProjectTile(
                    title: project.title,
                    url: project.url,
                    onTap: () => _openUrl(project.url),
                  ),
                ),
                const SizedBox(height: 24),
                _sectionHeader('GitHub & Activity'),
                const SizedBox(height: 10),
                _statsCard(profile),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _roundIconButton(IconData icon, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: CircleAvatar(
        radius: 22,
        backgroundColor: Colors.black.withValues(alpha: 0.25),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statsCard(ProfileData profile) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xff1B2235),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            profile.githubUsername,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          const Row(
            children: [
              Expanded(
                child: _StatBlock(label: 'Projects', value: '5+'),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _StatBlock(label: 'Streak', value: '12d'),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _StatBlock(label: 'Hours', value: '184'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProjectTile extends StatelessWidget {
  final String title;
  final String url;
  final VoidCallback onTap;

  const _ProjectTile({
    required this.title,
    required this.url,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xff1B2235),
        borderRadius: BorderRadius.circular(18),
      ),
      child: ListTile(
        title: Text(title, style: const TextStyle(color: Colors.white)),
        subtitle: Text(
          url,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Colors.white54),
        ),
        trailing: const Icon(Icons.open_in_new, color: Colors.greenAccent),
        onTap: onTap,
      ),
    );
  }
}

class _StatBlock extends StatelessWidget {
  final String label;
  final String value;

  const _StatBlock({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xff101522),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.greenAccent,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }
}
