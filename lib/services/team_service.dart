import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/team_model.dart';

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
      members: (data['members'] as int?) ?? 1,
      ownerId: (data['ownerId'] ?? '').toString(),
    );
  }

  static Stream<List<TeamModel>> streamTeams() {
    return _teamsRef
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(_fromDoc).toList());
  }

  static Stream<List<TeamModel>> streamOwnedTeams(String ownerId) {
    return _teamsRef
        .where('ownerId', isEqualTo: ownerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(_fromDoc).toList());
  }

  static Stream<List<TeamModel>> streamJoinedTeams(String userId) {
    return _teamsRef
        .where('memberIds', arrayContains: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(_fromDoc).toList());
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
    await FirebaseFirestore.instance.runTransaction((txn) async {
      final snapshot = await txn.get(ref);
      if (!snapshot.exists) return;

      final data = snapshot.data() ?? <String, dynamic>{};
      final members = (data['members'] as int?) ?? 1;
      final memberIds = ((data['memberIds'] as List<dynamic>?) ?? <dynamic>[])
          .map((e) => e.toString())
          .toList();

      if (members >= maxMembers || memberIds.contains(userId)) {
        return;
      }

      txn.update(ref, {
        'members': members + 1,
        'memberIds': FieldValue.arrayUnion([userId]),
      });
    });
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
