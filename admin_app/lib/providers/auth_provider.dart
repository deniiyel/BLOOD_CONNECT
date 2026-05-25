import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/models.dart';
import '../services/auth_service.dart';
import '../utils/firebase_errors.dart';

class AppAuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  UserModel? _user;
  bool _isLoading = false;
  String? _error;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _user != null;
  bool get isAdmin => _user?.isAdmin ?? false;

  // ── Auth state listener ──────────────────────

  void initialize() {
    _authService.authStateChanges.listen((User? firebaseUser) async {
      if (firebaseUser == null) {
        _user = null;
        notifyListeners();
        return;
      }
      try {
        _user = await _authService.getUserData(firebaseUser.uid);
        if (_user == null) {
          _error = 'Account profile missing. Please log out and register again.';
        } else {
          _error = null;
        }
      } catch (e) {
        _user = null;
        _error = friendlyFirebaseError(e);
      }
      notifyListeners();
    });
  }

  // ── Register ─────────────────────────────────

  Future<bool> register({
    required String email,
    required String password,
    required String fullName,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _user = await _authService.registerWithEmailAndPassword(
        email: email,
        password: password,
        fullName: fullName,
      );
      return true;
    } catch (e) {
      _error = friendlyFirebaseError(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Login ─────────────────────────────────────

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _user = await _authService.loginWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (_user == null) {
        _error = 'Profile not found. Log out and register again, or contact support.';
        return false;
      }
      return true;
    } catch (e) {
      _error = friendlyFirebaseError(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Logout ────────────────────────────────────

  Future<void> logout() async {
    await _authService.logout();
    _user = null;
    _error = null;
    notifyListeners();
  }

  // ── Password reset ────────────────────────────

  Future<bool> sendPasswordReset(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _authService.sendPasswordResetEmail(email);
      return true;
    } catch (e) {
      _error = friendlyFirebaseError(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Refresh ───────────────────────────────────

  Future<void> refreshUser() async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) return;
    try {
      _user = await _authService.getUserData(currentUser.uid);
      notifyListeners();
    } catch (e) {
      // Silently fail — existing session stays valid
      debugPrint('refreshUser error: $e');
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
