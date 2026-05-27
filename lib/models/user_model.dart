class UserModel {
  final String id;

  final String name;

  final String email;

  final String bio;

  final String github;

  final List<String> skills;

  final String profileImage;

  UserModel({
    required this.id,

    required this.name,

    required this.email,

    required this.bio,

    required this.github,

    required this.skills,

    required this.profileImage,
  });
}
