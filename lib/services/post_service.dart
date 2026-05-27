import '../models/post_model.dart';

class PostService {
  static List<PostModel> posts = [
    PostModel(
      id: "1",

      userId: "1",

      caption: "Building a new app 🚀",

      image: "",

      likes: 122,
    ),

    PostModel(
      id: "2",

      userId: "1",

      caption: "Looking for teammates",

      image: "",

      likes: 50,
    ),
  ];
}
