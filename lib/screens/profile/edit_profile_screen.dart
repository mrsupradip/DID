import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/firestore_service.dart';
import '../../services/profile_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final FirestoreService firestoreService = FirestoreService();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController bioController = TextEditingController();
  final TextEditingController githubController = TextEditingController();
  final TextEditingController skillsController = TextEditingController();
  final TextEditingController projectTitleController = TextEditingController();
  final TextEditingController projectUrlController = TextEditingController();

  bool loading = true;
  bool saving = false;
  String? profileImagePath;
  String? headerImagePath;
  List<ProjectLink> projects = [];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await ProfileService.loadProfile();
    if (!mounted) return;
    setState(() {
      nameController.text = profile.displayName;
      bioController.text = profile.bio;
      githubController.text = profile.githubUsername;
      skillsController.text = profile.skills.join(', ');
      profileImagePath = profile.profileImagePath.isEmpty
          ? null
          : profile.profileImagePath;
      headerImagePath = profile.headerImagePath.isEmpty
          ? null
          : profile.headerImagePath;
      projects = List<ProjectLink>.from(profile.projects);
      loading = false;
    });
  }

  @override
  void dispose() {
    nameController.dispose();
    bioController.dispose();
    githubController.dispose();
    skillsController.dispose();
    projectTitleController.dispose();
    projectUrlController.dispose();
    super.dispose();
  }

  void _addProject() {
    final title = projectTitleController.text.trim();
    final url = projectUrlController.text.trim();

    if (title.isEmpty || url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add both project title and URL')),
      );
      return;
    }

    setState(() {
      projects = [...projects, ProjectLink(title: title, url: url)];
      projectTitleController.clear();
      projectUrlController.clear();
    });
  }

  Future<void> _pickImage({required bool header}) async {
    final result = await FilePicker.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: false,
    );
    if (!mounted || result == null || result.files.isEmpty) return;

    setState(() {
      if (header) {
        headerImagePath = result.files.single.path;
      } else {
        profileImagePath = result.files.single.path;
      }
    });
  }

  Future<void> _save() async {
    final name = nameController.text.trim();
    final bio = bioController.text.trim();
    final github = githubController.text.trim();
    final skills = skillsController.text
        .split(',')
        .map((skill) => skill.trim())
        .where((skill) => skill.isNotEmpty)
        .toList();

    if (name.isEmpty || bio.isEmpty || github.isEmpty || skills.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Fill all profile fields')));
      return;
    }

    setState(() => saving = true);

    try {
      final profile = await ProfileService.loadProfile();
      final updated = profile.copyWith(
        displayName: name,
        bio: bio,
        githubUsername: github,
        skills: skills,
        profileImagePath: profileImagePath ?? '',
        headerImagePath: headerImagePath ?? '',
        projects: projects,
      );

      await ProfileService.saveProfile(updated);

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await firestoreService.updateUser(
          uid: user.uid,
          data: {'name': name, 'bio': bio, 'github': github, 'skills': skills},
        );
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save profile: $e')));
    } finally {
      if (mounted) {
        setState(() => saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        backgroundColor: Color(0xff101522),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xff101522),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Edit Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            GestureDetector(
              onTap: () => _pickImage(header: true),
              child: Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xff1B2235),
                  borderRadius: BorderRadius.circular(20),
                  image: headerImagePath == null
                      ? null
                      : DecorationImage(
                          image: FileImage(File(headerImagePath!)),
                          fit: BoxFit.cover,
                        ),
                ),
                child: const Center(
                  child: Text(
                    'Tap to change header',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () => _pickImage(header: false),
              child: CircleAvatar(
                radius: 56,
                backgroundColor: Colors.greenAccent,
                child: CircleAvatar(
                  radius: 52,
                  backgroundColor: const Color(0xff1B2235),
                  backgroundImage: profileImagePath == null
                      ? null
                      : FileImage(File(profileImagePath!)),
                  child: profileImagePath == null
                      ? const Icon(Icons.person, size: 54, color: Colors.white)
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 20),
            _field(controller: nameController, hint: 'Display name'),
            _field(controller: bioController, hint: 'Bio', maxLines: 3),
            _field(controller: githubController, hint: 'GitHub username'),
            _field(
              controller: skillsController,
              hint: 'Skills, comma separated',
            ),
            const SizedBox(height: 10),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Projects',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 10),
            _field(controller: projectTitleController, hint: 'Project title'),
            _field(controller: projectUrlController, hint: 'Project URL'),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _addProject,
                child: const Text('Add Project'),
              ),
            ),
            const SizedBox(height: 10),
            ...projects.map(
              (project) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xff1B2235),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            project.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            project.url,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white54),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          projects.remove(project);
                        });
                      },
                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.greenAccent,
                  padding: const EdgeInsets.all(16),
                ),
                child: saving
                    ? const CircularProgressIndicator(color: Colors.black)
                    : const Text(
                        'Save Profile',
                        style: TextStyle(color: Colors.black),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.grey),
          filled: true,
          fillColor: const Color(0xff1B2235),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}
