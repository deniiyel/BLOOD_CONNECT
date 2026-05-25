import 'dart:async';

import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/firestore_service.dart';
import '../utils/firebase_errors.dart';

// ─────────────────────────────────────────────
// DONOR PROVIDER
// ─────────────────────────────────────────────
class DonorProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  DonorModel? _donorProfile;
  List<DonorModel> _searchResults = [];
  List<DonorModel> _availableDonors = [];
  List<DonorModel> _liveSearchResults = [];
  bool _isLoading = false;
  bool _isSearching = false;
  String? _error;

  StreamSubscription<DonorModel?>? _donorProfileSub;
  StreamSubscription<List<DonorModel>>? _searchSub;
  // Dynamic hybrid search updates ko track aur cancel karne ke liye dedicated subscription
  StreamSubscription<List<DonorModel>>? _donorSearchSubscription;
  String? _watchedDonorId;

  DonorModel? get donorProfile => _donorProfile;
  List<DonorModel> get searchResults => _searchResults;
  List<DonorModel> get availableDonors => _availableDonors;
  List<DonorModel> get liveSearchResults => _liveSearchResults;
  bool get isLoading => _isLoading;
  bool get isSearching => _isSearching;
  String? get error => _error;
  bool get hasProfile => _donorProfile != null;

  // ── Live donor profile listener ──────────────

  void watchDonorProfile(String uid) {
    if (_watchedDonorId == uid && _donorProfileSub != null) return;
    _donorProfileSub?.cancel();
    _watchedDonorId = uid;
    _donorProfileSub = _firestoreService.donorStream(uid).listen(
      (donor) {
        _donorProfile = donor;
        notifyListeners();
      },
      onError: (Object e) {
        _error = friendlyFirebaseError(e);
        notifyListeners();
      },
    );
  }

  // ── Live donor search listener ────────────────

  void watchDonorSearch({String? bloodGroup, String? city}) {
    final normalizedCity = _blankToNull(city);

    _searchSub?.cancel();
    _isSearching = true;
    _error = null;
    notifyListeners();

    _searchSub = _firestoreService
        .searchDonorsStream(
          bloodGroup: bloodGroup,
          city: normalizedCity,
        )
        .listen(
      (donors) {
        _availableDonors = donors;
        _liveSearchResults = donors;
        _isSearching = false;
        notifyListeners();
      },
      onError: (Object e) {
        _error = friendlyFirebaseError(e);
        _availableDonors = [];
        _liveSearchResults = [];
        _isSearching = false;
        notifyListeners();
      },
    );
  }

  void stopWatchingSearch() {
    _searchSub?.cancel();
    _searchSub = null;
    _availableDonors = [];
    _liveSearchResults = [];
    _isSearching = false;
    notifyListeners();
  }

  String? _blankToNull(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  Stream<DonorModel?> donorStream(String uid) {
    return _firestoreService.donorStream(uid);
  }

  // ── One-shot load ─────────────────────────────

  Future<void> loadDonorProfile(String uid) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _donorProfile = await _firestoreService.getDonor(uid);
    } catch (e) {
      _error = friendlyFirebaseError(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Save ──────────────────────────────────────

  Future<bool> saveDonorProfile(DonorModel donor) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _firestoreService.saveDonorProfile(donor);
      _donorProfile = donor;
      return true;
    } catch (e) {
      _error = friendlyFirebaseError(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Toggle availability ───────────────────────

  Future<void> toggleAvailability(String uid, bool isAvailable) async {
    try {
      await _firestoreService.toggleDonorAvailability(uid, isAvailable);
      if (_donorProfile != null) {
        _donorProfile = _donorProfile!.copyWith(isAvailable: isAvailable);
        notifyListeners();
      }
    } catch (e) {
      _error = friendlyFirebaseError(e);
      notifyListeners();
    }
  }

  // ── One-shot search modified to support Realtime Sync ───

  Future<void> searchDonors({
    String? bloodGroup,
    String? city,
  }) async {
    _isSearching = true;
    _error = null;
    notifyListeners();

    // 1. Purani chalne wali search subscription ko cancel karte hain memory leaks aur overlap se bachne ke liye
    await _donorSearchSubscription?.cancel();

    try {
      // 2. Pehle direct one-shot query se data le aate hain taake UI par instantaneous response aaye
      _searchResults = await _firestoreService.searchDonors(
        bloodGroup: bloodGroup,
        city: city,
      );
      _isSearching = false;
      notifyListeners();

      // 3. Ab background me real-time stream pipeline bind karte hain taake database changes automatic sync hon
      _donorSearchSubscription = _firestoreService.searchDonorsStream(
        bloodGroup: bloodGroup,
        city: city,
      ).listen(
        (donorsList) {
          _liveSearchResults = donorsList;
          _searchResults = donorsList; // Structural consistency fallback check
          _error = null;
          notifyListeners();
        },
        onError: (Object e) {
          _error = friendlyFirebaseError(e);
          notifyListeners();
        },
      );

    } catch (e) {
      _error = friendlyFirebaseError(e);
      _searchResults = [];
      _liveSearchResults = [];
      _isSearching = false;
      notifyListeners();
    }
  }

  Stream<List<DonorModel>> searchDonorsStream({
    String? bloodGroup,
    String? city,
  }) {
    return _firestoreService.searchDonorsStream(
      bloodGroup: bloodGroup,
      city: city,
    );
  }

  void clearSearch() {
    _searchResults = [];
    _liveSearchResults = [];
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _donorProfileSub?.cancel();
    _searchSub?.cancel();
    _donorSearchSubscription?.cancel(); // New search listener stream cleanup
    super.dispose();
  }
}

// ─────────────────────────────────────────────
// REQUEST PROVIDER
// ─────────────────────────────────────────────
class RequestProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  List<RequestModel> _donorRequests = [];
  List<RequestModel> _recipientRequests = [];
  List<RequestModel> _pendingDonorRequests = [];

  StreamSubscription<List<RequestModel>>? _donorRequestsSub;
  StreamSubscription<List<RequestModel>>? _recipientRequestsSub;
  StreamSubscription<List<RequestModel>>? _pendingDonorRequestsSub;
  String? _watchedDonorId;
  String? _watchedRecipientId;

  bool _isLoading = false;
  String? _error;
  String? _successMessage;

  List<RequestModel> get donorRequests => _donorRequests;
  List<RequestModel> get recipientRequests => _recipientRequests;
  List<RequestModel> get pendingDonorRequests => _pendingDonorRequests;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get successMessage => _successMessage;

  // ── Watch donor requests ──────────────────────

  void watchDonorRequests(String donorId) {
    if (_watchedDonorId == donorId &&
        _donorRequestsSub != null &&
        _pendingDonorRequestsSub != null) {
      return;
    }

    _stopDonorWatch();
    _watchedDonorId = donorId;

    _donorRequestsSub =
        _firestoreService.donorRequestsStream(donorId).listen(
      (requests) {
        _donorRequests = requests;
        notifyListeners();
      },
      onError: (Object e) {
        _error = friendlyFirebaseError(e);
        notifyListeners();
      },
    );

    _pendingDonorRequestsSub =
        _firestoreService.pendingDonorRequestsStream(donorId).listen(
      (requests) {
        _pendingDonorRequests = requests;
        notifyListeners();
      },
      onError: (Object e) {
        _error = friendlyFirebaseError(e);
        notifyListeners();
      },
    );
  }

  // ── Watch recipient requests ──────────────────

  void watchRecipientRequests(String recipientId) {
    if (_watchedRecipientId == recipientId && _recipientRequestsSub != null) return;
    _recipientRequestsSub?.cancel();
    _watchedRecipientId = recipientId;

    _recipientRequestsSub =
        _firestoreService.recipientRequestsStream(recipientId).listen(
      (requests) {
        _recipientRequests = requests;
        notifyListeners();
      },
      onError: (Object e) {
        _error = friendlyFirebaseError(e);
        notifyListeners();
      },
    );
  }

  void _stopDonorWatch() {
    _donorRequestsSub?.cancel();
    _pendingDonorRequestsSub?.cancel();
    _donorRequestsSub = null;
    _pendingDonorRequestsSub = null;
    _watchedDonorId = null;
    _donorRequests = [];
    _pendingDonorRequests = [];
  }

  // ── Stream accessors ──────────────────────────

  Stream<List<RequestModel>> donorRequestsStream(String donorId) =>
      _firestoreService.donorRequestsStream(donorId);

  Stream<List<RequestModel>> recipientRequestsStream(String recipientId) =>
      _firestoreService.recipientRequestsStream(recipientId);

  Stream<List<RequestModel>> pendingDonorRequestsStream(String donorId) =>
      _firestoreService.pendingDonorRequestsStream(donorId);

  Stream<List<AppNotificationModel>> notificationsStream(String userId) =>
      _firestoreService.notificationsStream(userId);

  // ── Create request ────────────────────────────

  Future<bool> createRequest(RequestModel request) async {
    _isLoading = true;
    _error = null;
    _successMessage = null;
    notifyListeners();
    try {
      final exists = await _firestoreService.hasExistingRequest(
        recipientId: request.recipientId,
        donorId: request.donorId,
      );
      if (exists) {
        _error = 'You already have a pending request with this donor.';
        return false;
      }
      await _firestoreService.createRequest(request);
      _successMessage = 'Request sent successfully!';
      return true;
    } catch (e) {
      _error = friendlyFirebaseError(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Status updates ────────────────────────────

  Future<bool> acceptRequest(String requestId) async {
    try {
      await _firestoreService.acceptRequest(requestId);
      return true;
    } catch (e) {
      _error = friendlyFirebaseError(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> rejectRequest(String requestId) async {
    try {
      await _firestoreService.rejectRequest(requestId);
      return true;
    } catch (e) {
      _error = friendlyFirebaseError(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> completeRequest(String requestId, String donorId) async {
    try {
      await _firestoreService.completeRequestWithDonation(requestId, donorId);
      return true;
    } catch (e) {
      _error = friendlyFirebaseError(e);
      notifyListeners();
      return false;
    }
  }

  void clearMessages() {
    _error = null;
    _successMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _donorRequestsSub?.cancel();
    _recipientRequestsSub?.cancel();
    _pendingDonorRequestsSub?.cancel();
    super.dispose();
  }
}