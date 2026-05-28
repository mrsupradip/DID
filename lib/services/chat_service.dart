import '../models/message_model.dart';

class ChatContact {
  final String id;
  final String name;
  final String role;
  final String avatar;
  final bool isTeamChat;
  final List<MessageModel> messages;

  ChatContact({
    required this.id,
    required this.name,
    required this.role,
    required this.avatar,
    required this.isTeamChat,
    required this.messages,
  });

  String get lastMessage =>
      messages.isEmpty ? 'Start the conversation' : messages.last.message;

  DateTime get lastMessageTime =>
      messages.isEmpty ? DateTime.now() : messages.last.time;
}

class ChatService {
  static final List<ChatContact> conversations = [
    ChatContact(
      id: 'dev-1',
      name: 'Ava Chen',
      role: 'Flutter developer',
      avatar: 'AC',
      isTeamChat: false,
      messages: [
        MessageModel(
          senderId: 'ava',
          receiverId: 'me',
          message: 'Hey, are you still looking for a frontend partner?',
          time: DateTime.now().subtract(const Duration(minutes: 14)),
        ),
        MessageModel(
          senderId: 'me',
          receiverId: 'ava',
          message: 'Yes, I can help with the UI and Firebase.',
          time: DateTime.now().subtract(const Duration(minutes: 10)),
        ),
      ],
    ),
    ChatContact(
      id: 'team-1',
      name: 'Hackathon Crew',
      role: 'Team group',
      avatar: 'HC',
      isTeamChat: true,
      messages: [
        MessageModel(
          senderId: 'team',
          receiverId: 'me',
          message: 'Let’s ship the demo by tonight.',
          time: DateTime.now().subtract(const Duration(minutes: 38)),
        ),
      ],
    ),
    ChatContact(
      id: 'dev-2',
      name: 'Milo Johnson',
      role: 'Backend engineer',
      avatar: 'MJ',
      isTeamChat: false,
      messages: [
        MessageModel(
          senderId: 'milo',
          receiverId: 'me',
          message: 'I pushed the API mock for posts.',
          time: DateTime.now().subtract(const Duration(hours: 1)),
        ),
      ],
    ),
  ];

  static List<ChatContact> search(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return List<ChatContact>.from(conversations);

    return conversations
        .where(
          (conversation) =>
              conversation.name.toLowerCase().contains(normalized) ||
              conversation.role.toLowerCase().contains(normalized) ||
              conversation.lastMessage.toLowerCase().contains(normalized),
        )
        .toList();
  }

  static void sendMessage({
    required String conversationId,
    required String message,
  }) {
    final conversation = conversations.firstWhere(
      (entry) => entry.id == conversationId,
    );

    conversation.messages.add(
      MessageModel(
        senderId: 'me',
        receiverId: conversation.id,
        message: message,
        time: DateTime.now(),
      ),
    );
  }
}
