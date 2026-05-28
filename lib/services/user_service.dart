import '../models/user_model.dart';

class UserService {
  static UserModel currentUser = UserModel(
    id: "1",

    name: "Developer",

    email: "user@mail.com",

    bio: "Building awesome projects",

    github: "github.com/user",

    skills: ["Flutter", "Backend", "AI"],

    profileImage: "",
  );

  static void updateCurrentUser({
    required String name,
    required String email,
    required String bio,
    required String github,
    required List<String> skills,
    required String profileImage,
  }) {
    currentUser = UserModel(
      id: currentUser.id,
      name: name,
      email: email,
      bio: bio,
      github: github,
      skills: skills,
      profileImage: profileImage,
    );
  }
}
