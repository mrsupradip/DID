import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  Future<void> saveUser({
    required String uid,

    required String name,

    required String bio,

    required String github,

    required List<String> skills,
  }) async {
    await firestore.collection("users").doc(uid).set({
      "uid": uid,

      "name": name,

      "bio": bio,

      "github": github,

      "skills": skills,

      "createdAt": DateTime.now(),
    });
  }
}
