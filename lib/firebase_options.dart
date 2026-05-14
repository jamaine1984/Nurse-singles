import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for the Nurse Singles app.
///
/// These options are generated from the Firebase project
/// `nurse-singles-international`.
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
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return android; // fallback for desktop development
      case TargetPlatform.linux:
        return android; // fallback for desktop development
      case TargetPlatform.fuchsia:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyA4Yj4M2XJp_98cF8sN9MNwo52npOYiyDA',
    appId: '1:706493040190:android:396e8c6192f7b9dff1336f',
    messagingSenderId: '706493040190',
    projectId: 'nurse-singles-international',
    storageBucket: 'nurse-singles-international.firebasestorage.app',
  );

  // Placeholder iOS options – replace with actual values from Firebase console
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyA4Yj4M2XJp_98cF8sN9MNwo52npOYiyDA',
    appId: '1:706493040190:android:396e8c6192f7b9dff1336f',
    messagingSenderId: '706493040190',
    projectId: 'nurse-singles-international',
    storageBucket: 'nurse-singles-international.firebasestorage.app',
    iosBundleId: 'com.nightingaleheart.app',
  );

  // Placeholder macOS options
  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyA4Yj4M2XJp_98cF8sN9MNwo52npOYiyDA',
    appId: '1:706493040190:android:396e8c6192f7b9dff1336f',
    messagingSenderId: '706493040190',
    projectId: 'nurse-singles-international',
    storageBucket: 'nurse-singles-international.firebasestorage.app',
    iosBundleId: 'com.nightingaleheart.app',
  );

  // Placeholder web options
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyA4Yj4M2XJp_98cF8sN9MNwo52npOYiyDA',
    appId: '1:706493040190:android:396e8c6192f7b9dff1336f',
    messagingSenderId: '706493040190',
    projectId: 'nurse-singles-international',
    storageBucket: 'nurse-singles-international.firebasestorage.app',
    authDomain: 'nurse-singles-international.firebaseapp.com',
  );
}
