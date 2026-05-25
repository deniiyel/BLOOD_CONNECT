import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;

      case TargetPlatform.iOS:
        return ios;

      // Desktop uses web config for local development (run `flutterfire configure` for native apps)
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.macOS:
        return web;

      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAsh5G_fWoxomgDGiZNGJpLTXXOZZzgSzI',
    appId: '1:940229806451:web:f91af774ac819f74991d06',
    messagingSenderId: '940229806451',
    projectId: 'blood-connector-d0b1a',
    authDomain: 'blood-connector-d0b1a.firebaseapp.com',
    storageBucket: 'blood-connector-d0b1a.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBYuE2DH07QueX-9tmEDRnbkwZzRWinDEY',
    appId: '1:940229806451:android:4ff4426415b477dd991d06',
    messagingSenderId: '940229806451',
    projectId: 'blood-connector-d0b1a',
    storageBucket: 'blood-connector-d0b1a.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDa7coYOYztztFgLz6vVAyqn1Cxynw8lyg',
    appId: '1:940229806451:ios:000ed2198d0be84b991d06',
    messagingSenderId: '940229806451',
    projectId: 'blood-connector-d0b1a',
    storageBucket: 'blood-connector-d0b1a.firebasestorage.app',
    iosBundleId: 'com.bloodconnector.admin',
  );
}
