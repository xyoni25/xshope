import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
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

  // Configuration for Android from your google-services.json
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDrVKhA7D1jwbPwKCYZjVQo0Da6Zc3TUVE',
    appId: '1:627608960263:android:5b0b888066882cdc82d9a2',
    messagingSenderId: '627608960263',
    projectId: 'xshope-6428b',
    storageBucket: 'xshope-6428b.firebasestorage.app',
  );

  // For Web, iOS and macOS you'll need to get the configuration from Firebase console
  // These are placeholders - you should replace them with actual values
  static const FirebaseOptions web = FirebaseOptions(
    apiKey:
        'AIzaSyDrVKhA7D1jwbPwKCYZjVQo0Da6Zc3TUVE', // You might need a different API key for web
    appId: '1:627608960263:web:your_web_app_id_here',
    messagingSenderId: '627608960263',
    projectId: 'xshope-6428b',
    storageBucket: 'xshope-6428b.firebasestorage.app',
    authDomain: 'xshope-6428b.firebaseapp.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'your_ios_api_key_here',
    appId: '1:627608960263:ios:your_ios_app_id_here',
    messagingSenderId: '627608960263',
    projectId: 'xshope-6428b',
    storageBucket: 'xshope-6428b.firebasestorage.app',
    iosClientId: 'your_ios_client_id_here',
    iosBundleId: 'com.yonatan.xshope',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'your_macos_api_key_here',
    appId: '1:627608960263:macos:your_macos_app_id_here',
    messagingSenderId: '627608960263',
    projectId: 'xshope-6428b',
    storageBucket: 'xshope-6428b.firebasestorage.app',
    iosClientId: 'your_macos_client_id_here',
    iosBundleId: 'com.yonatan.xshope',
  );
}
