import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';
import '../utils/firebase_errors.dart';

/// Admin-only Firestore operations.
/// Requires Firestore security rules that allow reads/writes
/// when the caller's /users/{uid}.role == 'admin'.
class AdminService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Streams ──────────────────────────────────

  Stream<List<UserModel>> streamAllUsers() {
    return _db
        .collection('users')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => UserModel.fromMap(d.data(), d.id)).toList());
  }

  Stream<List<DonorModel>> streamAllDonors() {
    return _db
        .collection('donors')
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => DonorModel.fromMap(d.data(), d.id)).toList());
  }

  Stream<List<RequestModel>> streamAllRequests() {
    return _db
        .collection('requests')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => RequestModel.fromMap(d.data(), d.id)).toList());
  }

  // ── Delete User ──────────────────────────────

  /// Deletes user profile, donor profile (if any), and all related requests.
  /// Uses batched writes for atomicity.
  Future<void> deleteUserCompletely(String uid) async {
    try {
      final batch = _db.batch();

      // Requests where user is recipient
      final recipientRequests = await _db
          .collection('requests')
          .where('recipientId', isEqualTo: uid)
          .get();
      for (final doc in recipientRequests.docs) {
        batch.delete(doc.reference);
      }

      // Requests where user is donor
      final donorRequests = await _db
          .collection('requests')
          .where('donorId', isEqualTo: uid)
          .get();
      for (final doc in donorRequests.docs) {
        batch.delete(doc.reference);
      }

      // Donor profile (may not exist — delete is safe either way)
      batch.delete(_db.collection('donors').doc(uid));

      // User profile
      batch.delete(_db.collection('users').doc(uid));

      await batch.commit();
    } on FirebaseException catch (e) {
      throw friendlyFirebaseError(e);
    } catch (e) {
      throw friendlyFirebaseError(e);
    }
  }

  // ── Delete Donor ─────────────────────────────

  /// Deletes donor profile and all requests they are listed as donor in.
  Future<void> deleteDonorProfile(String uid) async {
    try {
      final batch = _db.batch();

      final donorRequests = await _db
          .collection('requests')
          .where('donorId', isEqualTo: uid)
          .get();
      for (final doc in donorRequests.docs) {
        batch.delete(doc.reference);
      }

      batch.delete(_db.collection('donors').doc(uid));
      await batch.commit();
    } on FirebaseException catch (e) {
      throw friendlyFirebaseError(e);
    } catch (e) {
      throw friendlyFirebaseError(e);
    }
  }

  // ── Delete Request ───────────────────────────

  Future<void> deleteRequest(String requestId) async {
    try {
      await _db.collection('requests').doc(requestId).delete();
    } on FirebaseException catch (e) {
      throw friendlyFirebaseError(e);
    } catch (e) {
      throw friendlyFirebaseError(e);
    }
  }

  Future<void> setAccountSuspended({
    required String uid,
    required bool suspended,
  }) async {
    try {
      final data = <String, dynamic>{
        'isSuspended': suspended,
        'suspendedAt': suspended ? FieldValue.serverTimestamp() : null,
      };

      final batch = _db.batch();
      batch.set(_db.collection('users').doc(uid), data, SetOptions(merge: true));
      batch.set(_db.collection('donors').doc(uid), data, SetOptions(merge: true));
      await batch.commit();
    } on FirebaseException catch (e) {
      throw friendlyFirebaseError(e);
    } catch (e) {
      throw friendlyFirebaseError(e);
    }
  }
}
