import '../models/message_model.dart';

class ChatService {
  static List<MessageModel> messages = [
    MessageModel(
      senderId: "1",

      receiverId: "2",

      message: "Hey interested?",

      time: DateTime.now(),
    ),
  ];
}
