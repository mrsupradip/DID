class TeamModel {
  final String id;
  final String teamCode;

  final String title;
  final String projectName;
  final String requiredMemberType;
  final String adminUserName;

  final String description;

  final List<String> requiredSkills;

  final int members;
  final List<String> memberIds;

  final String ownerId;

  TeamModel({
    required this.id,
    required this.teamCode,

    required this.title,
    required this.projectName,
    required this.requiredMemberType,
    required this.adminUserName,

    required this.description,

    required this.requiredSkills,

    required this.members,
    required this.memberIds,

    required this.ownerId,
  });
}
