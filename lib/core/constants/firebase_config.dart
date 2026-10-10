/// Pure Dart Firebase configuration for WardHelm (accessible from CLI & Web)
class FirebaseConfig {
  FirebaseConfig._();

  static const String projectId = 'wardhelm-app';
  static const String appId = '1:241268786812:web:wardhelm';
  static const String apiKey = 'AIzaSyAv1UJBarTIYIUA31PGPVDonjiKxUwbVOs';
  static const String authDomain = 'wardhelm-app.firebaseapp.com';
  static const String storageBucket = 'wardhelm-app.firebasestorage.app';
  static const String messagingSenderId = '241268786812';

  // REST API base URL for Firestore
  static const String firestoreRestUrl =
      'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents';
}
