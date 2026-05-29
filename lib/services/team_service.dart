import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/team_model.dart';
import 'social_service.dart';

class TeamService {
  static const int maxMembers = 5;
  static final CollectionReference<Map<String, dynamic>> _teamsRef =
      FirebaseFirestore.instance.collection('teams');

  static String _generateTeamCode() {
    final code = DateTime.now().microsecondsSinceEpoch % 9000000 + 1000000;
    return code.toString();
  }

  static TeamModel _fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final requiredSkillsRaw = data['requiredSkills'] as List<dynamic>?;

    // Firestore sometimes stores numbers as int and sometimes as num.
    final memberIds = _memberIdsFromData(data);
    final membersRaw = data['members'];
    final members = membersRaw is List
        ? membersRaw.length
        : (membersRaw is int
              ? membersRaw
              : (membersRaw is num ? membersRaw.toInt() : memberIds.length));

    return TeamModel(
      id: doc.id,
      teamCode: (data['teamCode'] ?? '').toString(),
      title: (data['title'] ?? '').toString(),
      projectName: (data['projectName'] ?? '').toString(),
      requiredMemberType: (data['requiredMemberType'] ?? '').toString(),
      adminUserName: (data['adminUserName'] ?? '').toString(),
      description: (data['description'] ?? '').toString(),
      requiredSkills: requiredSkillsRaw == null
          ? <String>[]
          : requiredSkillsRaw.map((e) => e.toString()).toList(),
      members: members,
      memberIds: memberIds,
      ownerId: (data['ownerId'] ?? '').toString(),
    );
  }

  static Stream<List<TeamModel>> streamTeams() {
    return _teamsRef
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(_fromDoc).toList());
  }

  /// Owned teams where `ownerId == currentUserId`.
  static Stream<List<TeamModel>> getOwnedTeams(String currentUserId) {
    return _teamsRef
        .where('ownerId', isEqualTo: currentUserId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(_fromDoc).toList());
  }

  /// Joined teams where `memberIds` contains `currentUserId`.
  static Stream<List<TeamModel>> getJoinedTeams(String currentUserId) {
    return streamTeams().map(
      (teams) => teams
          .where((team) => team.ownerId != currentUserId)
          .where((team) => team.memberIds.contains(currentUserId))
          .toList(),
    );
  }

  // Backwards compatibility for existing code.
  static Stream<List<TeamModel>> streamOwnedTeams(String ownerId) {
    return getOwnedTeams(ownerId);
  }

  static Stream<List<TeamModel>> streamJoinedTeams(String userId) {
    return getJoinedTeams(userId);
  }

  static List<TeamModel> search(List<TeamModel> teams, String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return List<TeamModel>.from(teams);

    return teams.where((team) {
      return team.title.toLowerCase().contains(normalized) ||
          team.projectName.toLowerCase().contains(normalized) ||
          team.description.toLowerCase().contains(normalized) ||
          team.requiredMemberType.toLowerCase().contains(normalized) ||
          team.requiredSkills.any(
            (skill) => skill.toLowerCase().contains(normalized),
          );
    }).toList();
  }

  static bool canJoin(TeamModel team) => team.members < maxMembers;

  static Future<void> joinTeam({
    required String teamId,
    required String userId,
  }) async {
    final ref = _teamsRef.doc(teamId);
    String? joinedOwnerId;
    String? joinedTeamTitle;
    await FirebaseFirestore.instance.runTransaction((txn) async {
      final snapshot = await txn.get(ref);
      if (!snapshot.exists) return;

      final data = snapshot.data() ?? <String, dynamic>{};
      final ownerId = (data['ownerId'] ?? '').toString();
      final teamTitle = (data['title'] ?? 'your team').toString();
      final membersRaw = data['members'];
      final memberIds = _memberIdsFromData(data);
      final members = membersRaw is List
          ? membersRaw.length
          : (membersRaw is int
                ? membersRaw
                : (membersRaw is num ? membersRaw.toInt() : memberIds.length));

      if (members >= maxMembers || memberIds.contains(userId)) {
        return;
      }

      if (membersRaw is List) {
        txn.update(ref, {
          'members': FieldValue.arrayUnion([userId]),
          'memberIds': FieldValue.arrayUnion([userId]),
        });
      } else {
        txn.update(ref, {
          'members': members + 1,
          'memberIds': FieldValue.arrayUnion([userId]),
        });
      }

      if (ownerId.isNotEmpty && ownerId != userId) {
        joinedOwnerId = ownerId;
        joinedTeamTitle = teamTitle;
      }
    });

    if (joinedOwnerId != null) {
      await SocialService().createNotification(
        uid: joinedOwnerId!,
        type: 'team_join',
        title: 'Team member joined',
        body: 'A developer joined ${joinedTeamTitle ?? 'your team'}',
        actorUid: userId,
        teamId: teamId,
      );
    }
  }

  static List<String> _memberIdsFromData(Map<String, dynamic> data) {
    final ids = <String>{};

    for (final field in const ['memberIds', 'members', 'joinedMembers']) {
      final raw = data[field];
      if (raw is List) {
        ids.addAll(raw.map((e) => e.toString()));
      }
    }

    final ownerId = (data['ownerId'] ?? '').toString();
    if (ownerId.isNotEmpty) ids.add(ownerId);

    return ids.toList();
  }

  static Future<void> createTeam({
    required String title,
    required String projectName,
    required String requiredMemberType,
    required String adminUserName,
    required String description,
    required List<String> requiredSkills,
    required String ownerId,
  }) async {
    await _teamsRef.add({
      'teamCode': _generateTeamCode(),
      'title': title,
      'projectName': projectName,
      'requiredMemberType': requiredMemberType,
      'adminUserName': adminUserName,
      'description': description,
      'requiredSkills': requiredSkills,
      'members': 1,
      'memberIds': [ownerId],
      'ownerId': ownerId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> deleteTeam({required String teamId}) async {
    final teamRef = _teamsRef.doc(teamId);
    final roomMessagesRef = FirebaseFirestore.instance
        .collection('team_rooms')
        .doc(teamId)
        .collection('messages');

    final messagesSnapshot = await roomMessagesRef.get();
    final batch = FirebaseFirestore.instance.batch();
    for (final doc in messagesSnapshot.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(teamRef);
    await batch.commit();
  }
}
