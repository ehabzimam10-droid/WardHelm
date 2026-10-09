/// Pure Dart Firebase configuration for WardHelm (accessible from CLI & Web)
class FirebaseConfig {
  FirebaseConfig._();

  static const String projectId = 'fadeinbox-bab5f';
  static const String appId = '1:120789632278:web:37721cb48ce7e2b8afbc37';
  static const String apiKey = 'AIzaSyAv1UJBarTIYIUA31PGPVDonjiKxUwbVOs';
  static const String authDomain = 'fadeinbox-bab5f.firebaseapp.com';
  static const String storageBucket = 'fadeinbox-bab5f.firebasestorage.app';
  static const String messagingSenderId = '120789632278';

  // REST API base URL for Firestore
  static const String firestoreRestUrl =
      'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents';
}
