import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';
import '../utils/firebase_errors.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─────────────────────────────────────────────
  // DONOR OPERATIONS
  // ─────────────────────────────────────────────

  /// Create or update donor profile (merge = true preserves existing fields)
  Future<void> saveDonorProfile(DonorModel donor) async {
    try {
      await _db.collection('donors').doc(donor.uid).set(
            donor.toMap(),
            SetOptions(merge: true),
          );
      await _db.collection('users').doc(donor.uid).set(
        {
          'fullName': donor.fullName,
          'phone': donor.phone,
          'city': donor.city,
          'cityLower': _normalizeSearchText(donor.city),
          'bloodGroup': donor.bloodGroup,
          'isAvailable': donor.isAvailable,
          'updatedAt': Timestamp.fromDate(donor.updatedAt),
        },
        SetOptions(merge: true),
      );
    } on FirebaseException catch (e) {
      throw friendlyFirebaseError(e);
    }
  }

  /// Fetch a single donor by UID (one-shot)
  Future<DonorModel?> getDonor(String uid) async {
    try {
      final doc = await _db.collection('donors').doc(uid).get();
      if (!doc.exists || doc.data() == null) return null;
      return DonorModel.fromMap(doc.data()!, uid);
    } on FirebaseException catch (e) {
      throw friendlyFirebaseError(e);
    }
  }

  /// Real-time stream for a donor's own profile
  Stream<DonorModel?> donorStream(String uid) {
    return _db.collection('donors').doc(uid).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return DonorModel.fromMap(doc.data()!, uid);
    });
  }

  /// Toggle availability — safe even if donor document doesn't fully exist yet
  Future<void> toggleDonorAvailability(
      String uid, bool isAvailable) async {
    try {
      await _db.collection('donors').doc(uid).set(
        {
          'uid': uid,
          'isAvailable': isAvailable,
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        },
        SetOptions(merge: true),
      );
      await _db.collection('users').doc(uid).set(
        {
          'isAvailable': isAvailable,
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        },
        SetOptions(merge: true),
      );
    } on FirebaseException catch (e) {
      throw friendlyFirebaseError(e);
    }
  }

  /// One-shot donor search
  Future<List<DonorModel>> searchDonors({
    String? bloodGroup,
    String? city,
    bool availableOnly = false,
    bool healthyOnly = true,
  }) async {
    try {
      final hasCityFilter = city != null && city.trim().isNotEmpty;
      final cityFilter = hasCityFilter ? _normalizeSearchText(city) : null;
      var donors = await _loadMergedDonors();
      if (cityFilter != null) {
        donors = donors
            .where((d) => _matchesCity(d.city, cityFilter))
            .toList();
      }
      if (bloodGroup != null && bloodGroup.isNotEmpty) {
        final bloodFilter = _normalizeBloodGroup(bloodGroup);
        donors = donors
            .where((d) => _normalizeBloodGroup(d.bloodGroup) == bloodFilter)
            .toList();
      }
      donors.sort(_donorSearchSort);
      return donors;
    } on FirebaseException catch (e) {
      throw friendlyFirebaseError(e);
    }
  }

  /// Live stream of donors. City searches are filtered locally.
  Stream<List<DonorModel>> searchDonorsStream({
    String? bloodGroup,
    String? city,
  }) {
    final hasCityFilter = city != null && city.trim().isNotEmpty;
    final cityFilter = hasCityFilter ? _normalizeSearchText(city) : null;

    return _db
        .collection('donors')
        .snapshots()
        .asyncMap((snap) async {
      final usersSnap = await _db
          .collection('users')
          .where('role', isEqualTo: 'donor')
          .get();

      final donorsById = <String, DonorModel>{};
      for (final doc in usersSnap.docs) {
        donorsById[doc.id] = DonorModel.fromMap(doc.data(), doc.id);
      }
      for (final doc in snap.docs) {
        donorsById[doc.id] = DonorModel.fromMap(doc.data(), doc.id);
      }

      var donors = donorsById.values.toList();
      if (cityFilter != null) {
        donors = donors
            .where((d) => _matchesCity(d.city, cityFilter))
            .toList();
      }
      if (bloodGroup != null && bloodGroup.isNotEmpty) {
        final bloodFilter = _normalizeBloodGroup(bloodGroup);
        donors = donors
            .where((d) => _normalizeBloodGroup(d.bloodGroup) == bloodFilter)
            .toList();
      }
      donors.sort(_donorSearchSort);
      return donors;
    });
  }

  Future<List<DonorModel>> _loadMergedDonors() async {
    final donorSnap = await _db.collection('donors').get();
    final usersSnap = await _db
        .collection('users')
        .where('role', isEqualTo: 'donor')
        .get();

    final donorsById = <String, DonorModel>{};
    for (final doc in usersSnap.docs) {
      donorsById[doc.id] = DonorModel.fromMap(doc.data(), doc.id);
    }
    for (final doc in donorSnap.docs) {
      donorsById[doc.id] = DonorModel.fromMap(doc.data(), doc.id);
    }
    return donorsById.values.toList();
  }

  String _normalizeSearchText(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  String _normalizeBloodGroup(String value) {
    return value.trim().toUpperCase().replaceAll(RegExp(r'\s+'), '');
  }

  bool _matchesCity(String donorCity, String cityFilter) {
    final normalizedCity = _normalizeSearchText(donorCity);
    if (normalizedCity.isEmpty) return false;
    return normalizedCity == cityFilter ||
        normalizedCity.contains(cityFilter) ||
        cityFilter.contains(normalizedCity);
  }

  int _donorSearchSort(DonorModel a, DonorModel b) {
    final byDonationReadiness =
        (b.canDonate ? 1 : 0).compareTo(a.canDonate ? 1 : 0);
    if (byDonationReadiness != 0) return byDonationReadiness;

    final byAvailability =
        (b.isAvailable ? 1 : 0).compareTo(a.isAvailable ? 1 : 0);
    if (byAvailability != 0) return byAvailability;

    return a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase());
  }

  // ─────────────────────────────────────────────
  // REQUEST OPERATIONS
  // ─────────────────────────────────────────────

  /// Create a new blood request and return the generated doc ID
  Future<String> createRequest(RequestModel request) async {
    try {
      final ref =
          await _db.collection('requests').add(request.toMap());
      await _createNotification(
        userId: request.donorId,
        title: 'New blood request',
        body:
            '${request.recipientName} needs ${request.bloodGroup} blood at ${request.hospital}.',
        type: 'request_created',
        requestId: ref.id,
      );
      return ref.id;
    } on FirebaseException catch (e) {
      throw friendlyFirebaseError(e);
    }
  }

  Future<void> updateRequestStatus({
    required String requestId,
    required String status,
    DateTime? respondedAt,
    DateTime? completedAt,
  }) async {
    final data = <String, dynamic>{'status': status};
    if (respondedAt != null) {
      data['respondedAt'] = Timestamp.fromDate(respondedAt);
    }
    if (completedAt != null) {
      data['completedAt'] = Timestamp.fromDate(completedAt);
    }
    try {
      await _db.collection('requests').doc(requestId).update(data);
      final doc = await _db.collection('requests').doc(requestId).get();
      final requestData = doc.data();
      if (requestData != null && status != 'pending') {
        final request = RequestModel.fromMap(requestData, doc.id);
        await _createNotification(
          userId: request.recipientId,
          title: 'Request ${request.statusLabel.toLowerCase()}',
          body:
              '${request.donorName} marked your ${request.bloodGroup} request as ${request.statusLabel.toLowerCase()}.',
          type: 'request_status_changed',
          requestId: request.id,
        );
      }
    } on FirebaseException catch (e) {
      throw friendlyFirebaseError(e);
    }
  }

  /// Live stream of all requests for a DONOR (incoming)
  /// Requires Firestore index: donorId ASC + createdAt DESC
  Stream<List<RequestModel>> donorRequestsStream(String donorId) {
    return _db
        .collection('requests')
        .where('donorId', isEqualTo: donorId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => RequestModel.fromMap(d.data(), d.id))
            .where((request) => !request.isExpired)
            .toList());
  }

  /// Live stream of all requests for a RECIPIENT (sent)
  /// Requires Firestore index: recipientId ASC + createdAt DESC
  Stream<List<RequestModel>> recipientRequestsStream(
      String recipientId) {
    return _db
        .collection('requests')
        .where('recipientId', isEqualTo: recipientId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => RequestModel.fromMap(d.data(), d.id))
            .toList());
  }

  /// Live stream of PENDING requests for a donor
  Stream<List<RequestModel>> pendingDonorRequestsStream(
      String donorId) {
    return _db
        .collection('requests')
        .where('donorId', isEqualTo: donorId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => RequestModel.fromMap(d.data(), d.id))
            .where((request) => !request.isExpired)
            .toList());
  }

  Future<void> acceptRequest(String requestId) async {
    await updateRequestStatus(
      requestId: requestId,
      status: 'accepted',
      respondedAt: DateTime.now(),
    );
  }

  Future<void> rejectRequest(String requestId) async {
    await updateRequestStatus(
      requestId: requestId,
      status: 'rejected',
      respondedAt: DateTime.now(),
    );
  }

  Future<void> completeRequest(String requestId) async {
    await updateRequestStatus(
      requestId: requestId,
      status: 'completed',
      completedAt: DateTime.now(),
    );
  }

  Future<void> completeRequestWithDonation(
    String requestId,
    String donorId,
  ) async {
    try {
      RequestModel? completedRequest;
      var didComplete = false;
      await _db.runTransaction((transaction) async {
        final requestRef = _db.collection('requests').doc(requestId);
        final donorRef = _db.collection('donors').doc(donorId);
        final requestDoc = await transaction.get(requestRef);
        final data = requestDoc.data();
        if (!requestDoc.exists || data == null) {
          throw FirebaseException(
            plugin: 'cloud_firestore',
            code: 'not-found',
            message: 'Request not found.',
          );
        }

        final request = RequestModel.fromMap(data, requestDoc.id);
        if (request.isCompleted) {
          return;
        }
        if (!request.isAccepted) {
          throw FirebaseException(
            plugin: 'cloud_firestore',
            code: 'failed-precondition',
            message: 'Only accepted requests can be completed.',
          );
        }

        final now = DateTime.now();
        transaction.update(requestRef, {
          'status': 'completed',
          'completedAt': Timestamp.fromDate(now),
        });
        transaction.set(
          donorRef,
          {
            'totalDonations': FieldValue.increment(1),
            'lastDonationDate': Timestamp.fromDate(now),
            'updatedAt': Timestamp.fromDate(now),
          },
          SetOptions(merge: true),
        );
        completedRequest = request.copyWith(
          status: 'completed',
          completedAt: now,
        );
        didComplete = true;
      });

      final request = completedRequest;
      if (didComplete && request != null) {
        await _createNotification(
          userId: request.recipientId,
          title: 'Request completed',
          body:
              '${request.donorName} completed your ${request.bloodGroup} donation request.',
          type: 'request_status_changed',
          requestId: request.id,
        );
      }
    } on FirebaseException catch (e) {
      throw friendlyFirebaseError(e);
    }
  }

  Stream<List<AppNotificationModel>> notificationsStream(String userId) {
    return _db
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snap) {
      final notifications = snap.docs
          .map((doc) => AppNotificationModel.fromMap(doc.data(), doc.id))
          .toList();
      notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return notifications;
    });
  }

  Future<void> _createNotification({
    required String userId,
    required String title,
    required String body,
    required String type,
    String? requestId,
  }) async {
    await _db.collection('notifications').add(
          AppNotificationModel(
            id: '',
            userId: userId,
            title: title,
            body: body,
            type: type,
            requestId: requestId,
            createdAt: DateTime.now(),
          ).toMap(),
        );
  }

  /// Returns true if there is already a pending request between
  /// this recipient and this donor — prevents duplicate requests.
  Future<bool> hasExistingRequest({
    required String recipientId,
    required String donorId,
  }) async {
    try {
      final snap = await _db
          .collection('requests')
          .where('recipientId', isEqualTo: recipientId)
          .where('donorId', isEqualTo: donorId)
          .where('status', isEqualTo: 'pending')
          .get();
      return snap.docs
          .map((d) => RequestModel.fromMap(d.data(), d.id))
          .any((request) => !request.isExpired);
    } on FirebaseException catch (e) {
      throw friendlyFirebaseError(e);
    }
  }

  // ─────────────────────────────────────────────
  // STATS
  // ─────────────────────────────────────────────

  Future<int> getTotalDonorsCount() async {
    final snap = await _db.collection('donors').count().get();
    return snap.count ?? 0;
  }

  Future<int> getAvailableDonorsCount() async {
    final snap = await _db
        .collection('donors')
        .where('isAvailable', isEqualTo: true)
        .count()
        .get();
    return snap.count ?? 0;
  }

  /// Increments totalDonations and sets lastDonationDate for a donor.
  Future<void> incrementDonorDonations(String donorId) async {
    try {
      await _db.collection('donors').doc(donorId).set(
        {
          'totalDonations': FieldValue.increment(1),
          'lastDonationDate': Timestamp.fromDate(DateTime.now()),
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        },
        SetOptions(merge: true),
      );
    } on FirebaseException catch (e) {
      throw friendlyFirebaseError(e);
    }
  }
}
