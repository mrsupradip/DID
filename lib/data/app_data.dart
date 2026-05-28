import '../services/user_service.dart';
import '../services/post_service.dart';
import '../services/chat_service.dart';
import '../models/message_model.dart';
import '../models/team_model.dart';

class AppData {
  static final user = UserService.currentUser;

  static final posts = PostService.posts;

  static const List<TeamModel> teams = <TeamModel>[];

  static List<MessageModel> get messages => ChatService.conversations
      .expand((conversation) => conversation.messages)
      .toList();
}
