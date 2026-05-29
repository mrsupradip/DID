import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/message_model.dart';
import 'chat_service.dart';

class DidUser {
  final String uid;
  final String name;
  final String email;
  final String github;

  const DidUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.github,
  });

  factory DidUser.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return DidUser(
      uid: doc.id,
      name: (data['name'] ?? data['displayName'] ?? 'Developer').toString(),
      email: (data['email'] ?? '').toString(),
      github: (data['github'] ?? '').toString(),
    );
  }
}

class SocialService {
  SocialService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  String? get currentUid => _auth.currentUser?.uid;

  Stream<List<DidUser>> streamUsers() {
    final uid = currentUid;
    return _firestore.collection('users').snapshots().asyncMap((
      snapshot,
    ) async {
      final excludedIds = <String>{};
      if (uid != null) excludedIds.add(uid);

      if (uid != null) {
        final friendships = await _firestore
            .collection('friendships')
            .where('memberIds', arrayContains: uid)
            .get();
        for (final doc in friendships.docs) {
          final memberIds =
              (doc.data()['memberIds'] as List<dynamic>? ?? <dynamic>[])
                  .map((e) => e.toString())
                  .toList();
          excludedIds.addAll(memberIds.where((memberId) => memberId != uid));

          final friendA = memberIds.isNotEmpty ? memberIds.first : '';
          final friendB = memberIds.length > 1 ? memberIds[1] : '';
          excludedIds.add(friendA);
          excludedIds.add(friendB);
        }

        final outgoingRequests = await _firestore
            .collection('friend_requests')
            .where('fromUid', isEqualTo: uid)
            .where('status', isEqualTo: 'pending')
            .get();
        for (final doc in outgoingRequests.docs) {
          excludedIds.add((doc.data()['toUid'] ?? '').toString());
        }

        final incomingRequests = await _firestore
            .collection('friend_requests')
            .where('toUid', isEqualTo: uid)
            .where('status', isEqualTo: 'pending')
            .get();
        for (final doc in incomingRequests.docs) {
          excludedIds.add((doc.data()['fromUid'] ?? '').toString());
        }
      }

      final users = snapshot.docs
          .map(DidUser.fromDoc)
          .where((user) => !excludedIds.contains(user.uid))
          .toList();
      users.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
      return users;
    });
  }

  Future<DidUser> findUserById(String uid) async {
    final normalized = uid.trim();
    if (normalized.isEmpty) throw StateError('Enter a D!D user id');

    final doc = await _firestore.collection('users').doc(normalized).get();
    if (!doc.exists) throw StateError('No D!D user found for that id');
    return DidUser.fromDoc(doc);
  }

  Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
  streamIncomingFriendRequests() {
    final uid = currentUid;
    if (uid == null) return const Stream.empty();

    return _firestore
        .collection('friend_requests')
        .where('toUid', isEqualTo: uid)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.docs);
  }

  Stream<List<ChatContact>> streamFriends() {
    final uid = currentUid;
    if (uid == null) return const Stream.empty();

    return _firestore
        .collection('friendships')
        .where('memberIds', arrayContains: uid)
        .snapshots()
        .asyncMap((snapshot) async {
          final contacts = <ChatContact>[];
          for (final doc in snapshot.docs) {
            final memberIds =
                (doc.data()['memberIds'] as List<dynamic>? ?? <dynamic>[])
                    .map((e) => e.toString())
                    .toList();
            final otherUid = memberIds.firstWhere(
              (id) => id != uid,
              orElse: () => '',
            );
            if (otherUid.isEmpty) continue;

            final userDoc = await _firestore
                .collection('users')
                .doc(otherUid)
                .get();
            if (!userDoc.exists) continue;

            final user = DidUser.fromDoc(userDoc);
            final latest = await _latestMessageWith(otherUid);
            contacts.add(
              ChatContact(
                id: user.uid,
                name: user.name,
                role: user.github.isEmpty
                    ? 'D!D friend'
                    : 'GitHub: ${user.github}',
                avatar: _initials(user.name),
                isTeamChat: false,
                messages: latest == null ? <MessageModel>[] : [latest],
              ),
            );
          }

          contacts.sort(
            (a, b) => b.lastMessageTime.compareTo(a.lastMessageTime),
          );
          return contacts;
        });
  }

  Stream<List<MessageModel>> streamMessagesWith(String otherUid) {
    final uid = currentUid;
    if (uid == null) return const Stream.empty();

    return _conversationRef(
      uid,
      otherUid,
    ).collection('messages').orderBy('createdAt').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        final createdAt = data['createdAt'];
        return MessageModel(
          senderId: (data['senderId'] ?? '').toString(),
          receiverId: (data['receiverId'] ?? '').toString(),
          message: (data['text'] ?? '').toString(),
          time: createdAt is Timestamp ? createdAt.toDate() : DateTime.now(),
        );
      }).toList();
    });
  }

  Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
  streamNotifications() {
    final uid = currentUid;
    if (uid == null) return const Stream.empty();

    return _firestore
        .collection('notifications')
        .where('uid', isEqualTo: uid)
        .snapshots()
        .map((snapshot) {
          final docs = [...snapshot.docs];
          docs.sort((a, b) {
            final aCreated = a.data()['createdAt'];
            final bCreated = b.data()['createdAt'];
            final aTime = aCreated is Timestamp
                ? aCreated.toDate()
                : DateTime.fromMillisecondsSinceEpoch(0);
            final bTime = bCreated is Timestamp
                ? bCreated.toDate()
                : DateTime.fromMillisecondsSinceEpoch(0);
            return bTime.compareTo(aTime);
          });
          return docs;
        });
  }

  Future<String> sendFriendRequest(DidUser user) async {
    final fromUid = currentUid;
    if (fromUid == null) throw StateError('Login required');
    if (fromUid == user.uid) throw StateError('You cannot add yourself');

    final friendshipId = _pairId(fromUid, user.uid);
    final friendship = await _firestore
        .collection('friendships')
        .doc(friendshipId)
        .get();
    if (friendship.exists) return 'Already friends';

    final reversePending = await _firestore
        .collection('friend_requests')
        .where('fromUid', isEqualTo: user.uid)
        .where('toUid', isEqualTo: fromUid)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .get();
    if (reversePending.docs.isNotEmpty) {
      return 'They already sent you a request';
    }

    final requestId = '${fromUid}_${user.uid}';
    final fromUser = await _currentUserProfile();
    await _firestore.collection('friend_requests').doc(requestId).set({
      'fromUid': fromUid,
      'fromName': fromUser?.name ?? 'Developer',
      'toUid': user.uid,
      'toName': user.name,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await createNotification(
      uid: user.uid,
      type: 'friend_request',
      title: 'Friend request',
      body: '${fromUser?.name ?? 'A developer'} sent you a friend request',
      actorUid: fromUid,
      requestId: requestId,
    );

    return 'Friend request sent';
  }

  Future<void> acceptFriendRequest(String requestId) async {
    final requestRef = _firestore.collection('friend_requests').doc(requestId);
    final request = await requestRef.get();
    if (!request.exists) return;

    final data = request.data() ?? <String, dynamic>{};
    final fromUid = (data['fromUid'] ?? '').toString();
    final toUid = (data['toUid'] ?? '').toString();
    if (fromUid.isEmpty || toUid.isEmpty) return;

    final friendshipId = _pairId(fromUid, toUid);
    final batch = _firestore.batch();
    batch.set(
      _firestore.collection('friendships').doc(friendshipId),
      {
        'memberIds': [fromUid, toUid],
        'createdAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    batch.update(requestRef, {'status': 'accepted'});
    await batch.commit();

    final toUser = await _firestore.collection('users').doc(toUid).get();
    final toName = DidUser.fromDoc(toUser).name;
    await createNotification(
      uid: fromUid,
      type: 'friend_accept',
      title: 'Friend request accepted',
      body: '$toName accepted your friend request',
      actorUid: toUid,
    );
  }

  Future<void> sendMessage({
    required String receiverUid,
    required String text,
  }) async {
    final senderUid = currentUid;
    if (senderUid == null) throw StateError('Login required');
    final message = text.trim();
    if (message.isEmpty) return;

    final conversationRef = _conversationRef(senderUid, receiverUid);
    await conversationRef.set({
      'participantIds': [senderUid, receiverUid],
      'updatedAt': FieldValue.serverTimestamp(),
      'lastMessage': message,
    }, SetOptions(merge: true));

    await conversationRef.collection('messages').add({
      'senderId': senderUid,
      'receiverId': receiverUid,
      'text': message,
      'createdAt': FieldValue.serverTimestamp(),
    });

    final sender = await _currentUserProfile();
    await createNotification(
      uid: receiverUid,
      type: 'message',
      title: 'New message',
      body: '${sender?.name ?? 'A friend'}: $message',
      actorUid: senderUid,
    );
  }

  Future<void> createNotification({
    required String uid,
    required String type,
    required String title,
    required String body,
    String? actorUid,
    String? requestId,
    String? teamId,
  }) async {
    if (uid.isEmpty) return;
    await _firestore.collection('notifications').add({
      'uid': uid,
      'type': type,
      'title': title,
      'body': body,
      'actorUid': actorUid,
      'requestId': requestId,
      'teamId': teamId,
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<DidUser?> _currentUserProfile() async {
    final uid = currentUid;
    if (uid == null) return null;
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) {
      return DidUser(
        uid: uid,
        name: _auth.currentUser?.displayName ?? 'Developer',
        email: _auth.currentUser?.email ?? '',
        github: '',
      );
    }
    return DidUser.fromDoc(doc);
  }

  Future<MessageModel?> _latestMessageWith(String otherUid) async {
    final uid = currentUid;
    if (uid == null) return null;

    final snapshot = await _conversationRef(uid, otherUid)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return null;

    final data = snapshot.docs.first.data();
    final createdAt = data['createdAt'];
    return MessageModel(
      senderId: (data['senderId'] ?? '').toString(),
      receiverId: (data['receiverId'] ?? '').toString(),
      message: (data['text'] ?? '').toString(),
      time: createdAt is Timestamp ? createdAt.toDate() : DateTime.now(),
    );
  }

  DocumentReference<Map<String, dynamic>> _conversationRef(
    String uid,
    String otherUid,
  ) {
    return _firestore.collection('conversations').doc(_pairId(uid, otherUid));
  }

  static String _pairId(String a, String b) {
    final ids = [a, b]..sort();
    return ids.join('_');
  }

  static String _initials(String name) {
    final initials = name
        .split(RegExp(r'[^a-zA-Z0-9]+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part.substring(0, 1).toUpperCase())
        .join();
    return initials.isEmpty ? 'D' : initials;
  }
}
