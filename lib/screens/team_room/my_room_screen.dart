import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/team_model.dart';
import '../../services/team_service.dart';
import 'team_room_detail_screen.dart';

class MyRoomScreen extends StatelessWidget {
  const MyRoomScreen({super.key});

  Future<void> _showCreateTeamSheet(
    BuildContext context,
    String ownerId,
  ) async {
    final teamNameController = TextEditingController();
    final projectNameController = TextEditingController();
    final memberTypeController = TextEditingController();
    final adminNameController = TextEditingController();
    final descriptionController = TextEditingController();
    final skillsController = TextEditingController();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: const Color(0xff101522),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20 + 16,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Create Team',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 18),
                _SheetField(controller: teamNameController, hint: 'Team name'),
                const SizedBox(height: 12),
                _SheetField(
                  controller: projectNameController,
                  hint: 'Project name',
                ),
                const SizedBox(height: 12),
                _SheetField(
                  controller: memberTypeController,
                  hint: 'What type of member is required',
                ),
                const SizedBox(height: 12),
                _SheetField(
                  controller: adminNameController,
                  hint: 'Team admin user name',
                ),
                const SizedBox(height: 12),
                _SheetField(
                  controller: descriptionController,
                  hint: 'Team description',
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                _SheetField(
                  controller: skillsController,
                  hint: 'Required skills, comma separated',
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final teamName = teamNameController.text.trim();
                      final projectName = projectNameController.text.trim();
                      final memberType = memberTypeController.text.trim();
                      final adminName = adminNameController.text.trim();
                      final description = descriptionController.text.trim();
                      final skills = skillsController.text
                          .split(',')
                          .map((skill) => skill.trim())
                          .where((skill) => skill.isNotEmpty)
                          .toList();

                      if (teamName.isEmpty ||
                          projectName.isEmpty ||
                          memberType.isEmpty ||
                          adminName.isEmpty ||
                          description.isEmpty ||
                          skills.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Fill all team fields before posting',
                            ),
                          ),
                        );
                        return;
                      }

                      await TeamService.createTeam(
                        title: teamName,
                        projectName: projectName,
                        requiredMemberType: memberType,
                        adminUserName: adminName,
                        description: description,
                        requiredSkills: skills,
                        ownerId: ownerId,
                      );

                      if (!context.mounted || !sheetContext.mounted) return;
                      Navigator.pop(sheetContext);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.greenAccent,
                      padding: const EdgeInsets.all(16),
                    ),
                    child: const Text(
                      'Create Team',
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    teamNameController.dispose();
    projectNameController.dispose();
    memberTypeController.dispose();
    adminNameController.dispose();
    descriptionController.dispose();
    skillsController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    if (currentUid == null) {
      return const Scaffold(
        backgroundColor: Color(0xff101522),
        body: Center(
          child: Text(
            'Login required',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xff101522),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('My Room'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Your teams and rooms',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Open a team to enter the team environment and discuss the project.',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _QuickActionCard(
                      title: 'Create Team',
                      subtitle: 'Start a new project room',
                      icon: Icons.add_circle_outline,
                      onTap: () {
                        final user = FirebaseAuth.instance.currentUser;
                        if (user == null) return;
                        _showCreateTeamSheet(context, user.uid);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Expanded(
                child: DefaultTabController(
                  length: 2,
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xff1A2233),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const TabBar(
                          indicatorColor: Colors.greenAccent,
                          labelColor: Colors.white,
                          unselectedLabelColor: Colors.white54,
                          tabs: [
                            Tab(text: 'Owned'),
                            Tab(text: 'Joined'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Expanded(
                        child: TabBarView(
                          children: [
                            _TeamList(
                              stream: TeamService.streamOwnedTeams(currentUid),
                              currentUid: currentUid,
                            ),
                            _TeamList(
                              stream: TeamService.streamJoinedTeams(currentUid),
                              currentUid: currentUid,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TeamList extends StatelessWidget {
  final Stream<List<TeamModel>> stream;
  final String currentUid;

  const _TeamList({required this.stream, required this.currentUid});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<TeamModel>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final teams = snapshot.data ?? <TeamModel>[];
        if (teams.isEmpty) {
          return const Center(
            child: Text(
              'No teams here yet.',
              style: TextStyle(color: Colors.white70),
            ),
          );
        }

        return ListView.separated(
          itemCount: teams.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final team = teams[index];
            final isOwner = team.ownerId == currentUid;
            return _TeamRoomCard(
              team: team,
              isOwner: isOwner,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TeamRoomDetailScreen(
                      team: team,
                      currentUid: currentUid,
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class _TeamRoomCard extends StatelessWidget {
  final TeamModel team;
  final bool isOwner;
  final VoidCallback onTap;

  const _TeamRoomCard({
    required this.team,
    required this.isOwner,
    required this.onTap,
  });

  Future<void> _deleteTeam(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xff101522),
        title: const Text('Delete team', style: TextStyle(color: Colors.white)),
        content: const Text(
          'This will remove the team and its room messages.',
          style: TextStyle(color: Colors.white70),
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

    if (confirmed != true) return;

    await TeamService.deleteTeam(teamId: team.id);
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xff1A2233),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.greenAccent.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.groups, color: Colors.greenAccent),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        team.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Code: ${team.teamCode}',
                        style: const TextStyle(color: Colors.greenAccent),
                      ),
                    ],
                  ),
                ),
                if (isOwner)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Chip(
                        label: Text('Owner'),
                        backgroundColor: Color(0xff101522),
                        labelStyle: TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () => _deleteTeam(context),
                        icon: const Icon(
                          Icons.delete_forever,
                          color: Colors.redAccent,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              team.projectName,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 8),
            Text(
              'Members ${team.members} / 5',
              style: const TextStyle(color: Colors.white54),
            ),
            const SizedBox(height: 4),
            Text(
              'Tap to enter team room',
              style: TextStyle(
                color: Colors.greenAccent.withValues(alpha: 0.85),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xff1A2233),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.greenAccent, size: 30),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(color: Colors.white54)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLines;

  const _SheetField({
    required this.controller,
    required this.hint,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey),
        filled: true,
        fillColor: const Color(0xff1B2235),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
