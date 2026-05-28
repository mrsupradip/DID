import '../models/team_model.dart';

class TeamService {
  static const int maxMembers = 5;

  static final List<TeamModel> teams = [
    TeamModel(
      id: "1",

      title: "Hackathon Team",

      description: "Need Flutter dev",

      requiredSkills: ["Flutter", "Firebase"],

      members: 3,

      ownerId: "1",
    ),
    TeamModel(
      id: "2",
      title: "AI Builder Squad",
      description: "Looking for prompt and UI builders",
      requiredSkills: ["AI", "Design", "Flutter"],
      members: 4,
      ownerId: "2",
    ),
    TeamModel(
      id: "3",
      title: "Backend Sprint",
      description: "API, auth, and database support",
      requiredSkills: ["Firebase", "Node.js", "API"],
      members: 2,
      ownerId: "3",
    ),
  ];

  static List<TeamModel> search(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return List<TeamModel>.from(teams);

    return teams.where((team) {
      return team.title.toLowerCase().contains(normalized) ||
          team.description.toLowerCase().contains(normalized) ||
          team.requiredSkills.any(
            (skill) => skill.toLowerCase().contains(normalized),
          );
    }).toList();
  }

  static bool canJoin(TeamModel team) => team.members < maxMembers;

  static void joinTeam(String teamId) {
    final index = teams.indexWhere((team) => team.id == teamId);
    if (index == -1) return;
    final team = teams[index];
    if (team.members >= maxMembers) return;

    teams[index] = TeamModel(
      id: team.id,
      title: team.title,
      description: team.description,
      requiredSkills: team.requiredSkills,
      members: team.members + 1,
      ownerId: team.ownerId,
    );
  }

  static void createTeam({
    required String title,
    required String description,
    required List<String> requiredSkills,
    required String ownerId,
  }) {
    teams.insert(
      0,
      TeamModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        description: description,
        requiredSkills: requiredSkills,
        members: 1,
        ownerId: ownerId,
      ),
    );
  }
}
