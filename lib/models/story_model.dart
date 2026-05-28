import 'package:cloud_firestore/cloud_firestore.dart';

class StoryModel {
  final String id;
  final String userId;
  final String imageUrl;
  final DateTime timestamp;
  final String username;
  final String profileImage;
  final String? caption;

  const StoryModel({
    required this.id,
    required this.userId,
    required this.imageUrl,
    required this.timestamp,
    required this.username,
    required this.profileImage,
    this.caption,
  });

  bool get isExpired =>
      DateTime.now().toUtc().difference(timestamp.toUtc()) >
      const Duration(hours: 24);

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'imageUrl': imageUrl,
      'timestamp': Timestamp.fromDate(timestamp.toUtc()),
      'username': username,
      'profileImage': profileImage,
      'caption': caption,
      'expiresAt': Timestamp.fromDate(
        timestamp.toUtc().add(const Duration(hours: 24)),
      ),
    };
  }

  factory StoryModel.fromMap(String id, Map<String, dynamic> map) {
    final timestampRaw = map['timestamp'];
    final timestamp = timestampRaw is Timestamp
        ? timestampRaw.toDate().toUtc()
        : DateTime.now().toUtc();

    return StoryModel(
      id: id,
      userId: (map['userId'] ?? '').toString(),
      imageUrl: (map['imageUrl'] ?? '').toString(),
      timestamp: timestamp,
      username: (map['username'] ?? 'Story').toString(),
      profileImage: (map['profileImage'] ?? '').toString(),
      caption: (map['caption'] ?? '').toString().isEmpty
          ? null
          : map['caption'].toString(),
    );
  }
}
