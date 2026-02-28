// File generated based on google-services.json configuration
// ignore_for_file: lines_longer_than_80_chars, avoid_classes_with_only_static_members
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'app/config/flavor_config.dart';

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
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web - '
        'you can reconfigure this by running the FlutterFire CLI again.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return FlavorConfig.isDriver ? androidDriver : androidPassenger;
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for iOS - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macOS - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for Windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for Linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions androidPassenger = FirebaseOptions(
    apiKey: 'AIzaSyA-3oBOl-D-ErM5JyFKGHWEGtORMo4iBn8',
    appId: '1:657234227532:android:6de0f950897774b199dfe9',
    messagingSenderId: '657234227532',
    projectId: 'vanyatra-69e38',
    storageBucket: 'vanyatra-69e38.firebasestorage.app',
  );

  static const FirebaseOptions androidDriver = FirebaseOptions(
    apiKey: 'AIzaSyA-3oBOl-D-ErM5JyFKGHWEGtORMo4iBn8',
    appId: '1:657234227532:android:84f15b4a64572b3a99dfe9',
    messagingSenderId: '657234227532',
    projectId: 'vanyatra-69e38',
    storageBucket: 'vanyatra-69e38.firebasestorage.app',
  );
}
