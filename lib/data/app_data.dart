import '../services/user_service.dart';
import '../services/post_service.dart';
import '../services/team_service.dart';
import '../services/chat_service.dart';

class AppData {
  static final user = UserService.currentUser;

  static final posts = PostService.posts;

  static final teams = TeamService.teams;

  static final messages = ChatService.messages;
}
