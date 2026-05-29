import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Firebase Auth user type is referenced via `FirebaseAuth.instance.currentUser`.

class AccountDeletionService {
  AccountDeletionService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  Future<void> deleteAccountCompletely({required String uid}) async {
    // Firestore cleanup first, then Auth deletion.
    await _deleteFirestoreUserData(uid);
    await _deleteAuthUser(uid);
  }

  Future<void> _deleteAuthUser(String uid) async {
    // If user is already deleted/sign-out, attempting delete can throw.
    final user = _auth.currentUser;
    if (user == null) return;

    // Only delete if current session matches.
    if (user.uid != uid) return;

    await user.delete();
    await _auth.signOut();
  }

  Future<void> _deleteFirestoreUserData(String uid) async {
    final writer = _BatchedWriter(_firestore);
    final ownedTeamIds = <String>{};

    // 1) Profile
    writer.delete(_firestore.collection('users').doc(uid));

    // 2) Posts owned by this user.
    final userPosts = await _firestore
        .collection('posts')
        .where('uid', isEqualTo: uid)
        .get();

    for (final doc in userPosts.docs) {
      writer.delete(doc.reference);
    }

    // 3) Quiz posts owned by this user.
    final quizPosts = await _firestore
        .collection('quiz_posts')
        .where('uid', isEqualTo: uid)
        .get();

    for (final doc in quizPosts.docs) {
      writer.delete(doc.reference);
    }

    // 4) Stories
    final stories = await _firestore
        .collection('stories')
        .where('userId', isEqualTo: uid)
        .get();

    for (final doc in stories.docs) {
      writer.delete(doc.reference);
    }

    // 5) Teams: owned teams
    final ownedTeams = await _firestore
        .collection('teams')
        .where('ownerId', isEqualTo: uid)
        .get();

    for (final doc in ownedTeams.docs) {
      final teamId = doc.id;
      ownedTeamIds.add(teamId);

      final messages = await _firestore
          .collection('team_rooms')
          .doc(teamId)
          .collection('messages')
          .get();

      for (final m in messages.docs) {
        writer.delete(m.reference);
      }

      writer.delete(_firestore.collection('team_rooms').doc(teamId));
      writer.delete(doc.reference);
    }

    // 6) Teams: joined memberships cleanup
    final joinedTeams = await _firestore
        .collection('teams')
        .where('memberIds', arrayContains: uid)
        .get();

    for (final doc in joinedTeams.docs) {
      if (ownedTeamIds.contains(doc.id)) continue;
      final data = doc.data();
      final membersRaw = data['members'];
      if (membersRaw is List) {
        writer.update(doc.reference, {
          'memberIds': FieldValue.arrayRemove([uid]),
          'members': FieldValue.arrayRemove([uid]),
        });
      } else {
        writer.update(doc.reference, {
          'memberIds': FieldValue.arrayRemove([uid]),
          'members': FieldValue.increment(-1),
        });
      }
    }

    // 7) Remove this user from post/quiz interaction arrays and embedded
    // comments on content owned by other users.
    await _removeUserFromContentCollection(
      collectionPath: 'posts',
      uid: uid,
      writer: writer,
    );
    await _removeUserFromContentCollection(
      collectionPath: 'quiz_posts',
      uid: uid,
      writer: writer,
    );

    // 8) Private chat/conversation cleanup for Firestore-backed variants.
    await _deleteWhere(
      collectionPath: 'chat_messages',
      field: 'senderId',
      uid: uid,
      writer: writer,
    );
    await _deleteWhere(
      collectionPath: 'chat_messages',
      field: 'receiverId',
      uid: uid,
      writer: writer,
    );
    await _deleteConversationWhereArrayContains(
      collectionPath: 'conversations',
      field: 'participantIds',
      uid: uid,
      writer: writer,
    );
    await _deleteConversationWhereArrayContains(
      collectionPath: 'conversations',
      field: 'participants',
      uid: uid,
      writer: writer,
    );
    await _deleteUserMessagesFromCollectionGroup(uid: uid, writer: writer);

    // 9) Notifications and friend requests. The app has used several uid field
    // names while evolving, so delete every known owner/actor variant.
    for (final field in const [
      'uid',
      'userId',
      'recipientId',
      'receiverId',
      'toUid',
      'fromUid',
      'actorUid',
    ]) {
      await _deleteWhere(
        collectionPath: 'notifications',
        field: field,
        uid: uid,
        writer: writer,
      );
    }

    for (final field in const [
      'fromUid',
      'toUid',
      'senderId',
      'receiverId',
      'requesterId',
      'recipientId',
      'uid',
    ]) {
      await _deleteWhere(
        collectionPath: 'friend_requests',
        field: field,
        uid: uid,
        writer: writer,
      );
    }

    await _deleteConversationWhereArrayContains(
      collectionPath: 'friendships',
      field: 'memberIds',
      uid: uid,
      writer: writer,
    );

    await writer.commit();
  }

  Future<void> _removeUserFromContentCollection({
    required String collectionPath,
    required String uid,
    required _BatchedWriter writer,
  }) async {
    final fields = [
      'likes',
      'dislikes',
      'saves',
      'savedBy',
      'votes',
      'shares',
      'commentUids',
    ];

    for (final field in fields) {
      final snapshot = await _firestore
          .collection(collectionPath)
          .where(field, arrayContains: uid)
          .get();

      for (final doc in snapshot.docs) {
        writer.update(doc.reference, {
          field: FieldValue.arrayRemove([uid]),
        });
      }
    }

    final commented = await _firestore.collection(collectionPath).get();

    for (final doc in commented.docs) {
      final data = doc.data();
      final comments = _withoutUserComments(data['comments'], uid);
      final rawComments = data['comments'];
      final originalLength = rawComments is List ? rawComments.length : 0;
      if (comments.length == originalLength) continue;

      writer.update(doc.reference, {'comments': comments});
    }
  }

  List<Map<String, dynamic>> _withoutUserComments(Object? raw, String uid) {
    final comments = raw is List ? raw : const <Object?>[];
    return comments
        .whereType<Map>()
        .map((entry) => entry.map((key, value) => MapEntry('$key', value)))
        .where((entry) => entry['uid'] != uid && entry['userId'] != uid)
        .toList();
  }

  Future<void> _deleteWhere({
    required String collectionPath,
    required String field,
    required String uid,
    required _BatchedWriter writer,
  }) async {
    final snapshot = await _firestore
        .collection(collectionPath)
        .where(field, isEqualTo: uid)
        .get();

    for (final doc in snapshot.docs) {
      writer.delete(doc.reference);
    }
  }

  Future<void> _deleteConversationWhereArrayContains({
    required String collectionPath,
    required String field,
    required String uid,
    required _BatchedWriter writer,
  }) async {
    final snapshot = await _firestore
        .collection(collectionPath)
        .where(field, arrayContains: uid)
        .get();

    for (final doc in snapshot.docs) {
      final messages = await doc.reference.collection('messages').get();
      for (final message in messages.docs) {
        writer.delete(message.reference);
      }
      writer.delete(doc.reference);
    }
  }

  Future<void> _deleteUserMessagesFromCollectionGroup({
    required String uid,
    required _BatchedWriter writer,
  }) async {
    final sent = await _firestore
        .collectionGroup('messages')
        .where('senderId', isEqualTo: uid)
        .get();
    for (final doc in sent.docs) {
      writer.delete(doc.reference);
    }

    final received = await _firestore
        .collectionGroup('messages')
        .where('receiverId', isEqualTo: uid)
        .get();
    for (final doc in received.docs) {
      writer.delete(doc.reference);
    }
  }
}

class _BatchedWriter {
  _BatchedWriter(this._firestore) : _batch = _firestore.batch();

  final FirebaseFirestore _firestore;
  WriteBatch _batch;
  int _pendingWrites = 0;
  final List<Future<void>> _commits = [];

  void delete(DocumentReference<Object?> reference) {
    _batch.delete(reference);
    _pendingWrites++;
    _commitIfFull();
  }

  void update(DocumentReference<Object?> reference, Map<String, Object?> data) {
    _batch.update(reference, data);
    _pendingWrites++;
    _commitIfFull();
  }

  Future<void> commit() async {
    if (_pendingWrites > 0) {
      _commits.add(_batch.commit());
      _batch = _firestore.batch();
      _pendingWrites = 0;
    }

    if (_commits.isEmpty) return;
    await Future.wait(_commits);
    _commits.clear();
  }

  void _commitIfFull() {
    if (_pendingWrites < 450) return;

    final batchToCommit = _batch;
    _batch = _firestore.batch();
    _pendingWrites = 0;
    _commits.add(batchToCommit.commit());
  }
}
