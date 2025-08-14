import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

class UserService {
  static const String usersCollection = 'users';

  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  Stream<List<AppUser>> streamUsers({int limit = 50}) {
    return _firestore
        .collection(usersCollection)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map(AppUser.fromDoc).toList());
  }

  Future<AppUser?> getCurrentUserProfile() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    final doc = await _firestore.collection(usersCollection).doc(uid).get();
    return doc.exists ? AppUser.fromDoc(doc) : null;
  }

  Future<void> createOrUpdateCurrentUser({
    required String name,
    required String email,
    String? photoUrl,
    String? bio,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw Exception('Not authenticated');
    }
    final ref = _firestore.collection(usersCollection).doc(uid);
    await ref.set({
      'name': name,
      'email': email,
      if (photoUrl != null) 'photoUrl': photoUrl,
      if (bio != null) 'bio': bio,
      'updatedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<AppUser?> getUser(String userId) async {
    final doc = await _firestore.collection(usersCollection).doc(userId).get();
    return doc.exists ? AppUser.fromDoc(doc) : null;
  }

  Future<void> updateUser(String userId, {String? name, String? bio, String? photoUrl}) async {
    final updates = <String, dynamic>{
      if (name != null) 'name': name,
      if (bio != null) 'bio': bio,
      if (photoUrl != null) 'photoUrl': photoUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (updates.isEmpty) return;
    await _firestore.collection(usersCollection).doc(userId).update(updates);
  }
}
