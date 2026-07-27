import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return android;
    }
    return web;
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDCVeqgqie2jB5ZGofEeD2UGsced9Nn8U8',
    appId: '1:198439372867:android:12e51e0436fd5573a16cf6',
    messagingSenderId: '198439372867',
    projectId: 'cashspark-c15bd',
    storageBucket: 'cashspark-c15bd.firebasestorage.app',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBhZaHYxQe9zya-075lYDYN7gmb5aUiAGQ',
    appId: '1:198439372867:web:9e0f89f17c3537c4a16cf6',
    messagingSenderId: '198439372867',
    projectId: 'cashspark-c15bd',
    authDomain: 'cashspark-c15bd.firebaseapp.com',
    storageBucket: 'cashspark-c15bd.firebasestorage.app',
  );
}
