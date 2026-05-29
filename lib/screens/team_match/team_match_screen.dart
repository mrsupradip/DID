import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../models/team_model.dart';
import '../../services/social_service.dart';
import '../../services/team_service.dart';
import '../team_room/team_room_detail_screen.dart';

class TeamMatchScreen extends StatefulWidget {
  const TeamMatchScreen({super.key});

  @override
  State<TeamMatchScreen> createState() => _TeamMatchScreenState();
}

class _TeamMatchScreenState extends State<TeamMatchScreen> {
  final SocialService _socialService = SocialService();
  String query = '';
  final Set<String> _joiningTeamIds = {};
  final Set<String> _requestingUserIds = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff101522),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Find Your Team'),
      ),
      body: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: DefaultTabController(
            length: 2,
            child: Column(
              children: [
                TextField(
                  onChanged: (value) => setState(() => query = value),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search teams or D!D users',
                    hintStyle: const TextStyle(color: Colors.grey),
                    prefixIcon: const Icon(Icons.search, color: Colors.white),
                    filled: true,
                    fillColor: const Color(0xff1B2235),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xff1B2235),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const TabBar(
                    indicatorColor: Colors.greenAccent,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white54,
                    tabs: [
                      Tab(text: 'Teams'),
                      Tab(text: 'People'),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildTeamsTab(),
                      _buildPeopleTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTeamsTab() {
    return StreamBuilder<List<TeamModel>>(
      stream: TeamService.streamTeams(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final allTeams = snapshot.data ?? <TeamModel>[];
        final currentUid = FirebaseAuth.instance.currentUser?.uid;
        final availableTeams = TeamService.search(allTeams, query)
            .where((team) => team.ownerId != currentUid)
            .where((team) => team.members < TeamService.maxMembers)
            .toList();

        if (availableTeams.isEmpty) {
          return const _EmptyTeamState();
        }

        return ListView.separated(
          itemCount: availableTeams.length,
          separatorBuilder: (_, _) => const SizedBox(height: 15),
          itemBuilder: (context, index) {
            final team = availableTeams[index];
            final currentUid = FirebaseAuth.instance.currentUser?.uid;
            final joined =
                currentUid != null && team.memberIds.contains(currentUid);
            final joining = _joiningTeamIds.contains(team.id);
            return TeamCard(
              team: team,
              joined: joined,
              joining: joining,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TeamRoomDetailScreen(
                      team: team,
                      currentUid: currentUid ?? '',
                    ),
                  ),
                );
              },
              onJoin: joining || joined
                  ? null
                  : () async {
                      final messenger = ScaffoldMessenger.of(context);

                      if (team.members >= TeamService.maxMembers) {
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('This team already has 5 members'),
                          ),
                        );
                        return;
                      }

                      final user = FirebaseAuth.instance.currentUser;
                      if (user == null) {
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('Login required to join teams'),
                          ),
                        );
                        return;
                      }

                      setState(() {
                        _joiningTeamIds.add(team.id);
                      });

                      try {
                        await TeamService.joinTeam(
                          teamId: team.id,
                          userId: user.uid,
                        );

                        if (!mounted) return;
                        messenger.showSnackBar(
                          const SnackBar(content: Text('Team joined')),
                        );
                      } catch (error) {
                        if (!mounted) return;
                        messenger.showSnackBar(
                          SnackBar(content: Text('Failed to join team: $error')),
                        );
                      } finally {
                        if (mounted) {
                          setState(() {
                            _joiningTeamIds.remove(team.id);
                          });
                        }
                      }
                    },
            );
          },
        );
      },
    );
  }

  Widget _buildPeopleTab() {
    return Column(
      children: [
        StreamBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
          stream: _socialService.streamIncomingFriendRequests(),
          builder: (context, snapshot) {
            final requests = snapshot.data ?? [];
            if (requests.isEmpty) return const SizedBox.shrink();

            return Column(
              children: [
                ...requests.map((request) {
                  final data = request.data();
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xff1B2235),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.person_add, color: Colors.greenAccent),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '${data['fromName'] ?? 'A developer'} sent a friend request',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            await _socialService.acceptFriendRequest(request.id);
                          },
                          child: const Text('Accept'),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 8),
              ],
            );
          },
        ),
        Expanded(
          child: StreamBuilder<List<DidUser>>(
            stream: _socialService.streamUsers(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final normalized = query.trim().toLowerCase();
              final users = (snapshot.data ?? <DidUser>[]).where((user) {
                if (normalized.isEmpty) return true;
                return user.name.toLowerCase().contains(normalized) ||
                    user.uid.toLowerCase().contains(normalized) ||
                    user.github.toLowerCase().contains(normalized);
              }).toList();

              if (users.isEmpty) {
                return const Center(
                  child: Text(
                    'No D!D users found.',
                    style: TextStyle(color: Colors.white70),
                  ),
                );
              }

              return ListView.separated(
                itemCount: users.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final user = users[index];
                  final requesting = _requestingUserIds.contains(user.uid);
                  return _UserFriendCard(
                    user: user,
                    requesting: requesting,
                    onRequest: requesting
                        ? null
                        : () async {
                            final messenger = ScaffoldMessenger.of(context);
                            setState(() => _requestingUserIds.add(user.uid));
                            try {
                              final message = await _socialService
                                  .sendFriendRequest(user);
                              if (!mounted) return;
                              messenger.showSnackBar(
                                SnackBar(content: Text(message)),
                              );
                            } catch (error) {
                              if (!mounted) return;
                              messenger.showSnackBar(
                                SnackBar(content: Text(error.toString())),
                              );
                            } finally {
                              if (mounted) {
                                setState(
                                  () => _requestingUserIds.remove(user.uid),
                                );
                              }
                            }
                          },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _EmptyTeamState extends StatelessWidget {
  const _EmptyTeamState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: const Color(0xff1B2235),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.groups_rounded,
              color: Colors.greenAccent,
              size: 56,
            ),
            const SizedBox(height: 12),
            const Text(
              'No available teams right now',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Open a team to see details or join if there is room.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserFriendCard extends StatelessWidget {
  final DidUser user;
  final bool requesting;
  final VoidCallback? onRequest;

  const _UserFriendCard({
    required this.user,
    required this.requesting,
    required this.onRequest,
  });

  @override
  Widget build(BuildContext context) {
    final initials = user.name
        .split(RegExp(r'[^a-zA-Z0-9]+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part.substring(0, 1).toUpperCase())
        .join();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xff1B2235),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.greenAccent,
            child: Text(
              initials.isEmpty ? 'D' : initials,
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  user.github.isEmpty ? user.uid : 'GitHub: ${user.github}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: requesting ? null : onRequest,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.greenAccent,
              foregroundColor: Colors.black,
            ),
            child: Text(requesting ? 'Sending...' : 'Add'),
          ),
        ],
      ),
    );
  }
}

class TeamCard extends StatelessWidget {
  final TeamModel team;
  final bool joined;
  final bool joining;
  final VoidCallback onTap;
  final VoidCallback? onJoin;

  const TeamCard({
    super.key,
    required this.team,
    required this.joined,
    required this.joining,
    required this.onTap,
    required this.onJoin,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(25),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xff1B2235),
          borderRadius: BorderRadius.circular(25),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.greenAccent,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Icon(Icons.groups, color: Colors.black),
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
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    '${team.members}/${TeamService.maxMembers}',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              'Project: ${team.projectName}',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 8),
            Text(
              'Need: ${team.requiredMemberType}',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 8),
            Text(
              'Admin: ${team.adminUserName}',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 8),
            Text(team.description, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: team.requiredSkills
                  .map(
                    (skill) => Chip(
                      label: Text(skill),
                      backgroundColor: Colors.white.withValues(alpha: 0.08),
                      labelStyle: const TextStyle(color: Colors.white70),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: joined || joining ? null : onJoin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.greenAccent,
                  foregroundColor: Colors.black,
                ),
                child: Text(
                  joining ? 'Joining...' : (joined ? 'Joined' : 'Join Team'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
