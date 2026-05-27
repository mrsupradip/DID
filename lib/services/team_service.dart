import '../models/team_model.dart';

class TeamService {
  static List<TeamModel> teams = [
    TeamModel(
      id: "1",

      title: "Hackathon Team",

      description: "Need Flutter dev",

      requiredSkills: ["Flutter", "Firebase"],

      members: 3,

      ownerId: "1",
    ),
  ];
}
