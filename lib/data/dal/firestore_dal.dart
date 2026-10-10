import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants/firebase_config.dart';

/// Data Access Layer (DAL) for Firestore.
/// Uses high-performance Firestore REST API to guarantee 100% cross-platform
/// reliability across Web, Windows Desktop, Android, and headless Dart agents.
class FirestoreDal {
  final http.Client _client;

  FirestoreDal({http.Client? client}) : _client = client ?? http.Client();

  static String? authToken;

  String get _baseUrl => FirebaseConfig.firestoreRestUrl;
  String get _apiKeyParam => '?key=${FirebaseConfig.apiKey}';

  Map<String, String> _headers([Map<String, String>? extra]) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (authToken != null && authToken!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $authToken';
    }
    if (extra != null) headers.addAll(extra);
    return headers;
  }

  /// Fetch a single document
  Future<Map<String, dynamic>?> getDocument(String collection, String docId) async {
    final uri = Uri.parse('$_baseUrl/$collection/$docId$_apiKeyParam');
    try {
      final response = await _client.get(uri, headers: _headers());
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body) as Map<String, dynamic>;
        return _decodeFirestoreFields(decoded['fields'] as Map<String, dynamic>? ?? {});
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// List all documents in a collection
  Future<List<Map<String, dynamic>>> getCollection(String collection) async {
    final uri = Uri.parse('$_baseUrl/$collection$_apiKeyParam');
    try {
      final response = await _client.get(uri, headers: _headers());
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body) as Map<String, dynamic>;
        final documents = decoded['documents'] as List<dynamic>? ?? [];
        return documents.map((doc) {
          final fields = (doc as Map<String, dynamic>)['fields'] as Map<String, dynamic>? ?? {};
          final name = doc['name'] as String? ?? '';
          final docId = name.split('/').last;
          final map = _decodeFirestoreFields(fields);
          map['id'] = docId;
          return map;
        }).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Create or update a document
  Future<bool> setDocument(String collection, String docId, Map<String, dynamic> data) async {
    final uri = Uri.parse('$_baseUrl/$collection/$docId$_apiKeyParam');
    final body = json.encode({
      'fields': _encodeFirestoreFields(data),
    });

    try {
      final response = await _client.patch(
        uri,
        headers: _headers(),
        body: body,
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  /// Delete a document
  Future<bool> deleteDocument(String collection, String docId) async {
    final uri = Uri.parse('$_baseUrl/$collection/$docId$_apiKeyParam');
    try {
      final response = await _client.delete(uri, headers: _headers());
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // --- Helper Encoders & Decoders for Firestore REST API ---

  Map<String, dynamic> _encodeFirestoreFields(Map<String, dynamic> map) {
    final Map<String, dynamic> fields = {};
    map.forEach((key, value) {
      if (key == 'id') return; // Firestore document ID is in the path
      fields[key] = _encodeValue(value);
    });
    return fields;
  }

  Map<String, dynamic> _encodeValue(dynamic value) {
    if (value == null) return {'nullValue': null};
    if (value is bool) return {'booleanValue': value};
    if (value is int) return {'integerValue': value.toString()};
    if (value is double) return {'doubleValue': value};
    if (value is String) return {'stringValue': value};
    if (value is List) {
      return {
        'arrayValue': {
          'values': value.map((v) => _encodeValue(v)).toList(),
        }
      };
    }
    if (value is Map<String, dynamic>) {
      return {
        'mapValue': {
          'fields': _encodeFirestoreFields(value),
        }
      };
    }
    return {'stringValue': value.toString()};
  }

  Map<String, dynamic> _decodeFirestoreFields(Map<String, dynamic> fields) {
    final Map<String, dynamic> result = {};
    fields.forEach((key, valMap) {
      result[key] = _decodeValue(valMap as Map<String, dynamic>);
    });
    return result;
  }

  dynamic _decodeValue(Map<String, dynamic> valueMap) {
    if (valueMap.containsKey('stringValue')) return valueMap['stringValue'];
    if (valueMap.containsKey('booleanValue')) return valueMap['booleanValue'];
    if (valueMap.containsKey('integerValue')) return int.tryParse(valueMap['integerValue'].toString()) ?? 0;
    if (valueMap.containsKey('doubleValue')) return (valueMap['doubleValue'] as num).toDouble();
    if (valueMap.containsKey('arrayValue')) {
      final values = valueMap['arrayValue']['values'] as List<dynamic>? ?? [];
      return values.map((v) => _decodeValue(v as Map<String, dynamic>)).toList();
    }
    if (valueMap.containsKey('mapValue')) {
      final fields = valueMap['mapValue']['fields'] as Map<String, dynamic>? ?? {};
      return _decodeFirestoreFields(fields);
    }
    return null;
  }
}
