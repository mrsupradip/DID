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
}
