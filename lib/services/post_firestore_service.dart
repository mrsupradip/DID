import 'package:cloud_firestore/cloud_firestore.dart';

class PostFirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> createPost({
    required String uid,
    required String caption,
    String? imageUrl,
  }) async {
    final doc = _db.collection('posts').doc();

    await doc.set({
      'id': doc.id,
      'uid': uid,
      'caption': caption,
      'imageUrl': imageUrl,
      'likes': <String>[],
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
