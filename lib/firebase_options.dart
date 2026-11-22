// PLACEHOLDER. Run `flutterfire configure` in the project root to replace this
// file with the real configuration of your Firebase project (see README.md).
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class DefaultFirebaseOptions {
  /// True while the placeholder values below have not been replaced.
  static bool get isPlaceholder => _android.apiKey == 'REPLACE_ME';

  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return _ios;
      default:
        return _android;
    }
  }

  static const FirebaseOptions _android = FirebaseOptions(
    apiKey: 'REPLACE_ME',
    appId: 'REPLACE_ME',
    messagingSenderId: 'REPLACE_ME',
    projectId: 'REPLACE_ME',
  );

  static const FirebaseOptions _ios = FirebaseOptions(
    apiKey: 'REPLACE_ME',
    appId: 'REPLACE_ME',
    messagingSenderId: 'REPLACE_ME',
    projectId: 'REPLACE_ME',
    iosBundleId: 'edu.sabanciuniv.cs310.pomodoroApp',
  );
}
