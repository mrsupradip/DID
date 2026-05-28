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
  static final List<ChatContact> conversations = [];

  static List<ChatContact> get friends =>
      conversations.where((conversation) => !conversation.isTeamChat).toList();

  static bool get hasFriends => friends.isNotEmpty;

  static void addFriend(String userIdOrGithub) {
    final normalized = userIdOrGithub.trim();
    if (normalized.isEmpty) return;

    final alreadyExists = conversations.any(
      (conversation) =>
          conversation.id == normalized ||
          conversation.name.toLowerCase() == normalized.toLowerCase(),
    );
    if (alreadyExists) return;

    final displayName = normalized
        .replaceAll('https://github.com/', '')
        .replaceAll('github.com/', '')
        .split('/')
        .last;
    final initials = displayName
        .split(RegExp(r'[^a-zA-Z0-9]+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part.substring(0, 1).toUpperCase())
        .join();

    conversations.insert(
      0,
      ChatContact(
        id: normalized,
        name: displayName,
        role: 'D!D friend',
        avatar: initials.isEmpty ? 'F' : initials,
        isTeamChat: false,
        messages: [
          MessageModel(
            senderId: normalized,
            receiverId: 'me',
            message: 'Say hi to $displayName.',
            time: DateTime.now(),
          ),
        ],
      ),
    );
  }

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
