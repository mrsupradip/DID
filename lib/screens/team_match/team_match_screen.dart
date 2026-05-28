import 'package:flutter/material.dart';

import '../../models/team_model.dart';
import '../../services/team_service.dart';

class TeamMatchScreen extends StatefulWidget {
  const TeamMatchScreen({super.key});

  @override
  State<TeamMatchScreen> createState() => _TeamMatchScreenState();
}

class _TeamMatchScreenState extends State<TeamMatchScreen> {
  String query = '';
  final Set<String> joinedTeamIds = {};

  Future<void> _showCreateTeamSheet() async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final skillsController = TextEditingController();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
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
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
          ),
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
              _SheetField(controller: titleController, hint: 'Team title'),
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
                  onPressed: () {
                    final title = titleController.text.trim();
                    final description = descriptionController.text.trim();
                    final skills = skillsController.text
                        .split(',')
                        .map((skill) => skill.trim())
                        .where((skill) => skill.isNotEmpty)
                        .toList();

                    if (title.isEmpty ||
                        description.isEmpty ||
                        skills.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Fill title, description, and skills'),
                        ),
                      );
                      return;
                    }

                    setState(() {
                      TeamService.createTeam(
                        title: title,
                        description: description,
                        requiredSkills: skills,
                        ownerId: 'me',
                      );
                    });

                    Navigator.pop(sheetContext);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.greenAccent,
                    padding: const EdgeInsets.all(16),
                  ),
                  child: const Text(
                    'Publish Team',
                    style: TextStyle(color: Colors.black),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff101522),

      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.greenAccent,
        onPressed: _showCreateTeamSheet,
        icon: const Icon(Icons.add, color: Colors.black),
        label: const Text('Create Team', style: TextStyle(color: Colors.black)),
      ),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              const Text(
                "Find Your Team",

                style: TextStyle(
                  color: Colors.white,

                  fontSize: 32,

                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

              TextField(
                onChanged: (value) => setState(() => query = value),
                style: const TextStyle(color: Colors.white),

                decoration: InputDecoration(
                  hintText: "Search skills...",

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

              const SizedBox(height: 25),

              Expanded(
                child: ListView.separated(
                  itemCount: TeamService.search(query).length,
                  separatorBuilder: (_, _) => const SizedBox(height: 15),
                  itemBuilder: (context, index) {
                    final team = TeamService.search(query)[index];
                    return TeamCard(
                      team: team,
                      joined: joinedTeamIds.contains(team.id),
                      onJoin: () {
                        if (team.members >= TeamService.maxMembers) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('This team already has 5 members'),
                            ),
                          );
                          return;
                        }

                        setState(() {
                          TeamService.joinTeam(team.id);
                          joinedTeamIds.add(team.id);
                        });
                      },
                    );
                  },
                ),
              ),
            ],
          ),
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

class TeamCard extends StatelessWidget {
  final TeamModel team;
  final bool joined;
  final VoidCallback onJoin;

  const TeamCard({
    super.key,
    required this.team,
    required this.joined,
    required this.onJoin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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

              const Spacer(),

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
                  '${team.members}/5',

                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          Text(
            team.title,

            style: const TextStyle(
              color: Colors.white,

              fontSize: 18,

              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          Text(team.description, style: const TextStyle(color: Colors.grey)),

          const SizedBox(height: 12),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: team.requiredSkills
                .map(
                  (skill) => Chip(
                    backgroundColor: const Color(0xff101522),
                    label: Text(
                      skill,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                )
                .toList(),
          ),

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,

            child: ElevatedButton(
              onPressed: joined || team.members >= TeamService.maxMembers
                  ? null
                  : onJoin,

              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.greenAccent,
              ),

              child: Text(
                joined ? 'Joined' : 'Join Team',
                style: const TextStyle(color: Colors.black),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
