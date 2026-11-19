// Firebase configuration for Shuttle Smashers
// Generated from google-services.json and GoogleService-Info.plist

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web - '
        'you can reconfigure this by running the FlutterFire CLI again.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCnUhFqJyIvZWTbtHUCttMP5OzWyB1o1Hw',
    appId: '1:292670387570:android:0d4fe73c6a6f52625cd9eb',
    messagingSenderId: '292670387570',
    projectId: 'shuttle-smashers-66023',
    storageBucket: 'shuttle-smashers-66023.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAxeqwYBMV3hDYyDPgD90z7WeD41FrvN5c',
    appId: '1:292670387570:ios:9e448c7e06ad0f505cd9eb',
    messagingSenderId: '292670387570',
    projectId: 'shuttle-smashers-66023',
    storageBucket: 'shuttle-smashers-66023.firebasestorage.app',
    iosBundleId: 'com.shuttlesmashers.app',
  );
}
