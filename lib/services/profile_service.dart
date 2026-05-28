import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'user_service.dart';

class ProjectLink {
  final String title;
  final String url;

  const ProjectLink({required this.title, required this.url});

  Map<String, dynamic> toMap() => {'title': title, 'url': url};

  factory ProjectLink.fromMap(Map<String, dynamic> map) {
    return ProjectLink(
      title: (map['title'] ?? '').toString(),
      url: (map['url'] ?? '').toString(),
    );
  }
}

class ProfileData {
  final String displayName;
  final String email;
  final String bio;
  final String githubUsername;
  final String profileImagePath;
  final String headerImagePath;
  final List<String> skills;
  final bool privateAccount;
  final bool showSkillsPublicly;
  final bool messagesNotifications;
  final bool teamRequestsNotifications;
  final bool darkTheme;
  final bool githubConnected;
  final String githubUrl;
  final List<ProjectLink> projects;

  const ProfileData({
    required this.displayName,
    required this.email,
    required this.bio,
    required this.githubUsername,
    required this.profileImagePath,
    required this.headerImagePath,
    required this.skills,
    required this.privateAccount,
    required this.showSkillsPublicly,
    required this.messagesNotifications,
    required this.teamRequestsNotifications,
    required this.darkTheme,
    required this.githubConnected,
    required this.githubUrl,
    required this.projects,
  });

  factory ProfileData.defaultData() {
    final user = UserService.currentUser;
    return ProfileData(
      displayName: user.name,
      email: user.email,
      bio: user.bio,
      githubUsername: user.github,
      profileImagePath: user.profileImage,
      headerImagePath: '',
      skills: List<String>.from(user.skills),
      privateAccount: true,
      showSkillsPublicly: false,
      messagesNotifications: true,
      teamRequestsNotifications: true,
      darkTheme: true,
      githubConnected: false,
      githubUrl:
          'https://github.com/${user.github.replaceAll('github.com/', '')}',
      projects: const [
        ProjectLink(title: 'D!D App', url: 'https://github.com/'),
        ProjectLink(title: 'Hackathon Demo', url: 'https://github.com/'),
        ProjectLink(title: 'Portfolio Site', url: 'https://github.com/'),
      ],
    );
  }

  ProfileData copyWith({
    String? displayName,
    String? email,
    String? bio,
    String? githubUsername,
    String? profileImagePath,
    String? headerImagePath,
    List<String>? skills,
    bool? privateAccount,
    bool? showSkillsPublicly,
    bool? messagesNotifications,
    bool? teamRequestsNotifications,
    bool? darkTheme,
    bool? githubConnected,
    String? githubUrl,
    List<ProjectLink>? projects,
  }) {
    return ProfileData(
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      bio: bio ?? this.bio,
      githubUsername: githubUsername ?? this.githubUsername,
      profileImagePath: profileImagePath ?? this.profileImagePath,
      headerImagePath: headerImagePath ?? this.headerImagePath,
      skills: skills ?? this.skills,
      privateAccount: privateAccount ?? this.privateAccount,
      showSkillsPublicly: showSkillsPublicly ?? this.showSkillsPublicly,
      messagesNotifications:
          messagesNotifications ?? this.messagesNotifications,
      teamRequestsNotifications:
          teamRequestsNotifications ?? this.teamRequestsNotifications,
      darkTheme: darkTheme ?? this.darkTheme,
      githubConnected: githubConnected ?? this.githubConnected,
      githubUrl: githubUrl ?? this.githubUrl,
      projects: projects ?? this.projects,
    );
  }

  Map<String, dynamic> toMap() => {
    'displayName': displayName,
    'email': email,
    'bio': bio,
    'githubUsername': githubUsername,
    'profileImagePath': profileImagePath,
    'headerImagePath': headerImagePath,
    'skills': skills,
    'privateAccount': privateAccount,
    'showSkillsPublicly': showSkillsPublicly,
    'messagesNotifications': messagesNotifications,
    'teamRequestsNotifications': teamRequestsNotifications,
    'darkTheme': darkTheme,
    'githubConnected': githubConnected,
    'githubUrl': githubUrl,
    'projects': projects.map((project) => project.toMap()).toList(),
  };

  factory ProfileData.fromMap(Map<String, dynamic> map) {
    final defaultData = ProfileData.defaultData();
    return ProfileData(
      displayName: (map['displayName'] ?? defaultData.displayName).toString(),
      email: (map['email'] ?? defaultData.email).toString(),
      bio: (map['bio'] ?? defaultData.bio).toString(),
      githubUsername: (map['githubUsername'] ?? defaultData.githubUsername)
          .toString(),
      profileImagePath:
          (map['profileImagePath'] ?? defaultData.profileImagePath).toString(),
      headerImagePath: (map['headerImagePath'] ?? defaultData.headerImagePath)
          .toString(),
      skills: (map['skills'] as List? ?? defaultData.skills)
          .map((skill) => skill.toString())
          .toList(),
      privateAccount:
          map['privateAccount'] as bool? ?? defaultData.privateAccount,
      showSkillsPublicly:
          map['showSkillsPublicly'] as bool? ?? defaultData.showSkillsPublicly,
      messagesNotifications:
          map['messagesNotifications'] as bool? ??
          defaultData.messagesNotifications,
      teamRequestsNotifications:
          map['teamRequestsNotifications'] as bool? ??
          defaultData.teamRequestsNotifications,
      darkTheme: map['darkTheme'] as bool? ?? defaultData.darkTheme,
      githubConnected:
          map['githubConnected'] as bool? ?? defaultData.githubConnected,
      githubUrl: (map['githubUrl'] ?? defaultData.githubUrl).toString(),
      projects: (map['projects'] as List? ?? defaultData.projects)
          .map(
            (project) =>
                ProjectLink.fromMap(Map<String, dynamic>.from(project as Map)),
          )
          .toList(),
    );
  }
}

class ProfileService {
  static const _profileKey = 'did_profile_state';
  static final ValueNotifier<ThemeMode> themeNotifier =
      ValueNotifier<ThemeMode>(ThemeMode.dark);

  static Future<ProfileData> loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_profileKey);
    if (raw == null || raw.isEmpty) {
      final profile = ProfileData.defaultData();
      themeNotifier.value = profile.darkTheme
          ? ThemeMode.dark
          : ThemeMode.light;
      return profile;
    }

    final profile = ProfileData.fromMap(
      jsonDecode(raw) as Map<String, dynamic>,
    );
    themeNotifier.value = profile.darkTheme ? ThemeMode.dark : ThemeMode.light;
    return profile;
  }

  static Future<void> saveProfile(ProfileData profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profileKey, jsonEncode(profile.toMap()));
    themeNotifier.value = profile.darkTheme ? ThemeMode.dark : ThemeMode.light;

    UserService.updateCurrentUser(
      id: UserService.currentUser.id,
      name: profile.displayName,
      email: profile.email,
      bio: profile.bio,
      github: profile.githubUsername,
      skills: profile.skills,
      profileImage: profile.profileImagePath,
    );
  }

  static Future<void> updateProfile(
    ProfileData Function(ProfileData current) update,
  ) async {
    final current = await loadProfile();
    await saveProfile(update(current));
  }

  static Future<void> updateTheme(bool darkTheme) async {
    await updateProfile((current) => current.copyWith(darkTheme: darkTheme));
  }

  static Future<void> setPrivateAccount(bool value) async {
    await updateProfile((current) => current.copyWith(privateAccount: value));
  }

  static Future<void> setShowSkillsPublicly(bool value) async {
    await updateProfile(
      (current) => current.copyWith(showSkillsPublicly: value),
    );
  }

  static Future<void> setMessagesNotifications(bool value) async {
    await updateProfile(
      (current) => current.copyWith(messagesNotifications: value),
    );
  }

  static Future<void> setTeamRequestsNotifications(bool value) async {
    await updateProfile(
      (current) => current.copyWith(teamRequestsNotifications: value),
    );
  }

  static Future<void> setGithubConnection({
    required bool connected,
    String? githubUsername,
    String? githubUrl,
  }) async {
    await updateProfile(
      (current) => current.copyWith(
        githubConnected: connected,
        githubUsername: githubUsername,
        githubUrl: githubUrl,
      ),
    );
  }

  static Future<void> updateProjects(List<ProjectLink> projects) async {
    await updateProfile((current) => current.copyWith(projects: projects));
  }
}
