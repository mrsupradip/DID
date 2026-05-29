import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../utils/image_source.dart';
import 'cloudinary_service.dart';

class PostFirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<String?> createPost({
    required String uid,
    required String caption,
    String? attachmentName,
    String? attachmentPath,
    String? attachmentType,
  }) async {
    if (uid.isEmpty) {
      throw StateError('Login required to create a post');
    }

    if (caption.trim().isEmpty &&
        (attachmentPath == null || attachmentPath.trim().isEmpty)) {
      throw StateError('Add text or an attachment before posting');
    }

    final doc = _db.collection('posts').doc();

    String? attachmentUrl;
    if (attachmentType == 'photo' &&
        attachmentPath != null &&
        attachmentPath.isNotEmpty) {
      try {
        // Prevent duplicate uploads if caller accidentally passes an already-uploaded URL.
        if (isNetworkImageUrl(attachmentPath)) {
          attachmentUrl = attachmentPath;
        } else {
          final file = File(attachmentPath);
          if (!await file.exists()) {
            throw StateError('Selected photo no longer exists');
          }

          attachmentUrl = await CloudinaryService.uploadImage(file);
          if (attachmentUrl.isEmpty) {
            throw StateError('Photo upload returned an empty URL');
          }
        }
      } catch (error, stackTrace) {
        debugPrint('Post photo upload failed: $error');
        debugPrintStack(stackTrace: stackTrace);
        rethrow;
      }
    }

    await doc.set({
      'id': doc.id,
      'uid': uid,
      'caption': caption,
      'attachmentName': attachmentName,
      'attachmentType': attachmentType,
      'attachmentUrl': attachmentUrl,
      'likes': <String>[],
      'dislikes': <String>[],
      'votes': <String>[],
      'saves': <String>[],
      'shares': <String>[],
      'comments': <Map<String, dynamic>>[],
      'commentUids': <String>[],
      'createdAt': FieldValue.serverTimestamp(),
    });

    return attachmentUrl;
  }

  Future<void> deletePost({required String postId}) async {
    await _db.collection('posts').doc(postId).delete();
  }
}
