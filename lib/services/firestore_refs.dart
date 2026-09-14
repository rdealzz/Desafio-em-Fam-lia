import 'package:cloud_firestore/cloud_firestore.dart';

/// Nomes de coleção e referências em um lugar só.
///
/// Concentrar aqui evita strings soltas pelo código e facilita uma futura
/// migração (ex.: virar subcoleções por família quando escalar).
class FirestoreRefs {
  FirestoreRefs(this._db);

  final FirebaseFirestore _db;

  static const String usersCollection = 'users';
  static const String familiesCollection = 'families';
  static const String activityLogsCollection = 'activity_logs';
  static const String feedPostsCollection = 'feed_posts';

  FirebaseFirestore get db => _db;

  CollectionReference<Map<String, dynamic>> get users =>
      _db.collection(usersCollection);

  CollectionReference<Map<String, dynamic>> get families =>
      _db.collection(familiesCollection);

  CollectionReference<Map<String, dynamic>> get activityLogs =>
      _db.collection(activityLogsCollection);

  CollectionReference<Map<String, dynamic>> get feedPosts =>
      _db.collection(feedPostsCollection);

  DocumentReference<Map<String, dynamic>> user(String uid) => users.doc(uid);

  DocumentReference<Map<String, dynamic>> family(String familyId) =>
      families.doc(familyId);
}
