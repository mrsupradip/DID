import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'cloudinary_service.dart';
import '../models/story_model.dart';
import '../utils/image_source.dart';

class StoryService {
  StoryService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _storiesRef =>
      _firestore.collection('stories');

  Stream<QuerySnapshot<Map<String, dynamic>>> watchActiveStories({
    required DateTime cutoff,
  }) {
    return _storiesRef
        .where('expiresAt', isGreaterThan: Timestamp.fromDate(cutoff))
        .orderBy('expiresAt')
        .snapshots();
  }

  Future<StoryModel> createStory({
    required String userId,
    required String username,
    required String profileImage,
    required String imagePath,
    String? caption,
  }) async {
    if (userId.isEmpty) {
      throw StateError('Login required to create a story');
    }

    if (imagePath.isEmpty) {
      throw StateError('Story image is required');
    }

    // Prevent duplicate uploads if caller accidentally passes an already-uploaded URL.
    if (isNetworkImageUrl(imagePath)) {
      final doc = _storiesRef.doc();
      final timestamp = DateTime.now().toUtc();
      final story = StoryModel(
        id: doc.id,
        userId: userId,
        imageUrl: imagePath,
        timestamp: timestamp,
        username: username.trim().isEmpty ? 'Story' : username.trim(),
        profileImage: profileImage,
        caption: caption?.trim().isEmpty == true ? null : caption?.trim(),
      );

      await doc.set(story.toMap());
      return story;
    }

    final file = File(imagePath);
    if (!await file.exists()) {
      throw StateError('Selected story image is missing');
    }

    final doc = _storiesRef.doc();

    try {
      final imageUrl = await CloudinaryService.uploadImage(file);
      if (imageUrl.isEmpty) {
        throw StateError('Story image upload returned an empty URL');
      }

      final timestamp = DateTime.now().toUtc();
      final story = StoryModel(
        id: doc.id,
        userId: userId,
        imageUrl: imageUrl,
        timestamp: timestamp,
        username: username.trim().isEmpty ? 'Story' : username.trim(),
        profileImage: profileImage,
        caption: caption?.trim().isEmpty == true ? null : caption?.trim(),
      );

      await doc.set(story.toMap());
      return story;
    } catch (error, stackTrace) {
      debugPrint('Story upload failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }
}
