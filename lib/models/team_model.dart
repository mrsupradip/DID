class TeamModel {
  final String id;

  final String title;

  final String description;

  final List<String> requiredSkills;

  final int members;

  final String ownerId;

  TeamModel({
    required this.id,

    required this.title,

    required this.description,

    required this.requiredSkills,

    required this.members,

    required this.ownerId,
  });
}
