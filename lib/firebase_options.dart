import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

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
      default:
        throw UnsupportedError(
            'DefaultFirebaseOptions are not supported for this platform.');
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: "AIzaSyBsrzhM2rplZm9xDyOArMwhyC2kBDf0QCg",
    appId: "1:772152576969:android:47f16e67304a573c927618",
    messagingSenderId: "772152576969",
    projectId: "scoe-322c3",
    storageBucket: "scoe-322c3.firebasestorage.app",
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: "YOUR_IOS_API_KEY",
    appId: "YOUR_IOS_APP_ID",
    messagingSenderId: "YOUR_SENDER_ID",
    projectId: "YOUR_PROJECT_ID",
    storageBucket: "YOUR_STORAGE_BUCKET",
    iosBundleId: "com.example.scoe",
    androidClientId: '',
    iosClientId: '',
    measurementId: '',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: "YOUR_WEB_API_KEY",
    appId: "YOUR_WEB_APP_ID",
    messagingSenderId: "YOUR_SENDER_ID",
    projectId: "YOUR_PROJECT_ID",
    storageBucket: "YOUR_STORAGE_BUCKET",
    measurementId: "YOUR_MEASUREMENT_ID",
  );
}
