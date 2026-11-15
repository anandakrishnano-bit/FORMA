// File generated for FORMA on Android matching google-services.json
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are only configured for Android.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAKS3twI7q3M3uzY01LTq3ZNK_bfPckdTs',
    appId: '1:993961077997:android:3ee4cb6859abeb6b2f70e4',
    messagingSenderId: '993961077997',
    projectId: 'forma-fitness-eafd3',
    storageBucket: 'forma-fitness-eafd3.firebasestorage.app',
  );
}
