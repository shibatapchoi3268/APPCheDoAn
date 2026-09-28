import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/user_model.dart';
import '../../data/models/daily_log_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Save/Update user profile
  Future<void> saveUser(UserModel user) async {
    await _db.collection('users').doc(user.uid).set(user.toMap(), SetOptions(merge: true));
  }

  // Get user profile
  Stream<UserModel> streamUser(String uid) {
    return _db.collection('users').doc(uid).snapshots().map((snap) => 
      UserModel.fromMap(snap.data() as Map<String, dynamic>));
  }

  // Save daily log
  Future<void> saveDailyLog(String uid, DailyLogModel log) async {
    await _db
        .collection('users')
        .doc(uid)
        .collection('daily_logs')
        .doc(log.date)
        .set(log.toMap(), SetOptions(merge: true));
  }

  // Get daily log for a specific date
  Stream<DailyLogModel> streamDailyLog(String uid, String date) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('daily_logs')
        .doc(date)
        .snapshots()
        .map((snap) {
          if (snap.exists) {
            return DailyLogModel.fromMap(snap.data() as Map<String, dynamic>);
          }
          return DailyLogModel(date: date);
        });
  }
}
