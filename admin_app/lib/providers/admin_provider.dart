import 'dart:async';

import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/admin_service.dart';
import '../utils/firebase_errors.dart';

// ─────────────────────────────────────────────
// ADMIN PROVIDER
// Bug fix: removed the duplicate AdminService class that was
// incorrectly defined inline here. It conflicted with the real
// admin_service.dart and caused "permission-denied" errors because
// the inline version used wrong field names (userId vs recipientId).
// ─────────────────────────────────────────────
class AdminProvider extends ChangeNotifier {
  final AdminService _service = AdminService();

  List<UserModel> _users = [];
  List<DonorModel> _donors = [];
  List<RequestModel> _requests = [];

  StreamSubscription<List<UserModel>>? _usersSub;
  StreamSubscription<List<DonorModel>>? _donorsSub;
  StreamSubscription<List<RequestModel>>? _requestsSub;

  bool _isLoading = false;
  String? _error;

  // ── Getters ──────────────────────────────────
  List<UserModel> get users => _users;
  List<DonorModel> get donors => _donors;
  List<RequestModel> get requests => _requests;
  bool get isLoading => _isLoading;
  String? get error => _error;

  int get userCount => _users.length;
  int get donorCount => _donors.length;
  int get requestCount => _requests.length;
  int get pendingCount => _requests.where((r) => r.isPending).length;
  int get emergencyCount => _requests.where((r) => r.isEmergency).length;

  // ── Lifecycle ────────────────────────────────

  /// Call once from AdminNav.initState via addPostFrameCallback.
  void startWatching() {
    _usersSub ??= _service.streamAllUsers().listen(
      (list) {
        _users = list;
        notifyListeners();
      },
      onError: (Object e) {
        _error = friendlyFirebaseError(e);
        notifyListeners();
      },
    );

    _donorsSub ??= _service.streamAllDonors().listen(
      (list) {
        _donors = list;
        notifyListeners();
      },
      onError: (Object e) {
        _error = friendlyFirebaseError(e);
        notifyListeners();
      },
    );

    _requestsSub ??= _service.streamAllRequests().listen(
      (list) {
        _requests = list;
        notifyListeners();
      },
      onError: (Object e) {
        _error = friendlyFirebaseError(e);
        notifyListeners();
      },
    );
  }

  void stopWatching() {
    _usersSub?.cancel();
    _donorsSub?.cancel();
    _requestsSub?.cancel();
    _usersSub = null;
    _donorsSub = null;
    _requestsSub = null;
  }

  @override
  void dispose() {
    stopWatching();
    super.dispose();
  }

  // ── Delete User ──────────────────────────────

  /// Deletes a user completely.
  /// Guards: cannot delete an admin; cannot delete if only one admin remains.
  Future<bool> deleteUser(String uid, {String? currentAdminUid}) async {
    // Self-delete guard
    if (currentAdminUid != null && uid == currentAdminUid) {
      _error = 'You cannot delete your own admin account.';
      notifyListeners();
      return false;
    }

    // Last-admin guard
    final targetUser = _users.firstWhere(
      (u) => u.uid == uid,
      orElse: () => UserModel(
        uid: uid,
        email: '',
        fullName: '',
        role: 'recipient',
        createdAt: DateTime.now(),
      ),
    );

    if (targetUser.isAdmin) {
      final adminCount = _users.where((u) => u.isAdmin).length;
      if (adminCount <= 1) {
        _error = 'Cannot delete the last admin account.';
        notifyListeners();
        return false;
      }
    }

    _setLoading(true);
    try {
      await _service.deleteUserCompletely(uid);
      _clearError();
      return true;
    } catch (e) {
      _error = friendlyFirebaseError(e);
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ── Delete Donor ─────────────────────────────

  Future<bool> deleteDonor(String uid) async {
    _setLoading(true);
    try {
      await _service.deleteDonorProfile(uid);
      _clearError();
      return true;
    } catch (e) {
      _error = friendlyFirebaseError(e);
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ── Delete Request ───────────────────────────

  Future<bool> deleteRequest(String requestId) async {
    _setLoading(true);
    try {
      await _service.deleteRequest(requestId);
      _clearError();
      return true;
    } catch (e) {
      _error = friendlyFirebaseError(e);
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> setAccountSuspended(String uid, bool suspended) async {
    _setLoading(true);
    try {
      await _service.setAccountSuspended(uid: uid, suspended: suspended);
      _clearError();
      return true;
    } catch (e) {
      _error = friendlyFirebaseError(e);
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ── Helpers ──────────────────────────────────

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  void clearError() => _clearError();
}
