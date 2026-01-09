import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for ios - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
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

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDrqpbU6ShWFExYuGzZcI7yD_I0iN4ThpM',
    appId: '1:843090921240:web:b6162376764418d208406d',
    messagingSenderId: '843090921240',
    projectId: 'freelancer-app-a7c71',
    authDomain: 'freelancer-app-a7c71.firebaseapp.com',
    storageBucket: 'freelancer-app-a7c71.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBNNkFq16a_vmyx9DG9Y59w-dC0E3VrvaI',
    appId: '1:843090921240:android:18d19d7a3974f19f08406d',
    messagingSenderId: '843090921240',
    projectId: 'freelancer-app-a7c71',
    storageBucket: 'freelancer-app-a7c71.firebasestorage.app',
  );
}
