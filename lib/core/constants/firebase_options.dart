import 'package:firebase_core/firebase_core.dart';
import 'firebase_config.dart';

/// Flutter FirebaseOptions
class DefaultFirebaseOptions {
  static const FirebaseOptions currentPlatform = FirebaseOptions(
    apiKey: FirebaseConfig.apiKey,
    appId: FirebaseConfig.appId,
    messagingSenderId: FirebaseConfig.messagingSenderId,
    projectId: FirebaseConfig.projectId,
    authDomain: FirebaseConfig.authDomain,
    storageBucket: FirebaseConfig.storageBucket,
  );
}
