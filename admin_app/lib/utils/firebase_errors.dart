import 'package:firebase_core/firebase_core.dart';

/// Converts Firebase/Firestore errors into short user-facing messages.
String friendlyFirebaseError(Object error) {
  if (error is FirebaseException) {
    switch (error.code) {
      case 'permission-denied':
        // This is the most common admin error.
        // Root cause: Firestore security rules don't recognise the user's role,
        // OR the rules file hasn't been deployed yet.
        // Fix: deploy firestore.rules with:
        //   firebase deploy --only firestore:rules
        return 'Permission denied. Ensure Firestore rules are deployed '
            '(firebase deploy --only firestore:rules) and your account '
            'role is set correctly in the database.';
      case 'not-found':
        return 'Record not found. It may have already been deleted.';
      case 'unavailable':
        return 'Service temporarily unavailable. Check your internet connection.';
      case 'unauthenticated':
        return 'Session expired. Please log in again.';
      case 'already-exists':
        return 'This record already exists.';
      case 'resource-exhausted':
        return 'Too many requests. Please wait a moment and try again.';
      case 'cancelled':
        return 'Operation cancelled.';
      case 'deadline-exceeded':
        return 'Request timed out. Check your connection and try again.';
      case 'failed-precondition':
        return 'Operation failed. A required index may be missing — '
            'check the Firestore console for index creation links.';
      default:
        return error.message ?? 'Firebase error (${error.code})';
    }
  }

  final text = error.toString();
  if (text.contains('permission-denied')) {
    return 'Permission denied — deploy your Firestore security rules.';
  }
  if (text.contains('FAILED_PRECONDITION') || text.contains('index')) {
    return 'A Firestore composite index is required. '
        'Check the Firebase console for a link to create it.';
  }
  return text.replaceAll('Exception: ', '');
}
