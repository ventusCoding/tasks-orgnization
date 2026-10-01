// PLACEHOLDER for the dev flavor — overwritten by:
//   flutterfire configure --project=<YOUR_FIREBASE_DEV_PROJECT_ID> --out=lib/firebase/firebase_options_dev.dart \
//     --platforms=android,ios --android-package-name=app.everslot.dev --ios-bundle-id=app.everslot.dev
// (docs/guide.md › Firebase). While the project id starts with YOUR_, Firebase stays off.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform, kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) throw UnsupportedError('Web is not configured');
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => android,
      TargetPlatform.iOS => ios,
      _ => throw UnsupportedError('Platform not configured'),
    };
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'YOUR_ANDROID_API_KEY',
    appId: 'YOUR_ANDROID_APP_ID',
    messagingSenderId: 'YOUR_SENDER_ID',
    projectId: 'YOUR_FIREBASE_PROJECT_ID',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'YOUR_IOS_API_KEY',
    appId: 'YOUR_IOS_APP_ID',
    messagingSenderId: 'YOUR_SENDER_ID',
    projectId: 'YOUR_FIREBASE_PROJECT_ID',
    iosBundleId: 'app.everslot.dev',
  );
}
