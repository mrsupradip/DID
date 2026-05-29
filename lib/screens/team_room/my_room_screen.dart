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
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _CreateTeamScreen(ownerId: ownerId),
      ),
    );

    if (created == true && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Team created')));
    }
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
                            Tab(text: 'Owned Teams'),
                            Tab(text: 'Joined Teams'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Expanded(
                        child: TabBarView(
                          children: [
                            _TeamList(
                              emptyText: 'You don’t own any teams yet.',
                              stream: TeamService.getOwnedTeams(currentUid),
                              currentUid: currentUid,
                            ),
                            _TeamList(
                              emptyText: 'You haven’t joined any teams yet.',
                              stream: TeamService.getJoinedTeams(currentUid),
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

class _CreateTeamScreen extends StatefulWidget {
  final String ownerId;

  const _CreateTeamScreen({required this.ownerId});

  @override
  State<_CreateTeamScreen> createState() => _CreateTeamScreenState();
}

class _CreateTeamScreenState extends State<_CreateTeamScreen> {
  final TextEditingController teamNameController = TextEditingController();
  final TextEditingController projectNameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  bool creating = false;

  @override
  void dispose() {
    teamNameController.dispose();
    projectNameController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  Future<void> _createTeam() async {
    if (creating) return;

    final teamName = teamNameController.text.trim();
    final projectName = projectNameController.text.trim();
    final description = descriptionController.text.trim();

    if (teamName.isEmpty || projectName.isEmpty || description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter team name, project name, and description'),
        ),
      );
      return;
    }

    final currentUser = FirebaseAuth.instance.currentUser;
    final adminName =
        (currentUser?.displayName ?? currentUser?.email ?? 'Team admin')
            .split('@')
            .first
            .trim();

    setState(() => creating = true);
    try {
      await TeamService.createTeam(
        title: teamName,
        projectName: projectName,
        requiredMemberType: 'Any member',
        adminUserName: adminName,
        description: description,
        requiredSkills: const <String>[],
        ownerId: widget.ownerId,
      );

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to create team: $error')));
    } finally {
      if (mounted) setState(() => creating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor: const Color(0xff101522),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Create Team'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomInset),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Keep it simple',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Add the basics and publish the team right away.',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 20),
              _SheetField(controller: teamNameController, hint: 'Team name'),
              const SizedBox(height: 12),
              _SheetField(
                controller: projectNameController,
                hint: 'Project name',
              ),
              const SizedBox(height: 12),
              _SheetField(
                controller: descriptionController,
                hint: 'Short description',
                maxLines: 4,
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: creating ? null : _createTeam,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.greenAccent,
                    padding: const EdgeInsets.all(16),
                  ),
                  child: creating
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          'Create Team',
                          style: TextStyle(color: Colors.black),
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
  final String emptyText;

  const _TeamList({
    required this.stream,
    required this.currentUid,
    required this.emptyText,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<TeamModel>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const Center(
            child: Text(
              'Teams are unavailable right now.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70),
            ),
          );
        }

        final teamsRaw = snapshot.data ?? <TeamModel>[];

        // Defensive de-dupe by team id (Firestore should not return duplicates,
        // but this keeps UI stable).
        final seen = <String>{};
        final teams = <TeamModel>[];
        for (final t in teamsRaw) {
          if (seen.add(t.id)) teams.add(t);
        }

        if (teams.isEmpty) {
          return Center(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xff1A2233),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                emptyText,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70),
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.only(bottom: 16),
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

    try {
      await TeamService.deleteTeam(teamId: team.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Team deleted')));
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to delete team: $error')));
    }
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
