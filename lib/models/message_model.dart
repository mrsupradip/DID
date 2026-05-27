class MessageModel {
  final String senderId;

  final String receiverId;

  final String message;

  final DateTime time;

  MessageModel({
    required this.senderId,

    required this.receiverId,

    required this.message,

    required this.time,
  });
}
