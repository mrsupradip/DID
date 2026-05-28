import 'package:cloud_firestore/cloud_firestore.dart';

class PostFirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> createPost({
    required String uid,
    required String caption,
    String? attachmentName,
    String? attachmentPath,
    String? attachmentType,
  }) async {
    final doc = _db.collection('posts').doc();

    await doc.set({
      'id': doc.id,
      'uid': uid,
      'caption': caption,
      'attachmentName': attachmentName,
      'attachmentPath': attachmentPath,
      'attachmentType': attachmentType,
      'likes': <String>[],
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
