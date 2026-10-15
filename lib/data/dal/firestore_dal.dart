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
  static int lastStatusCode = 200;
  static String? lastErrorMessage;
  static DateTime? _rateLimitedUntil;

  // Short in-memory cache to prevent redundant concurrent queries
  static final Map<String, List<Map<String, dynamic>>> _collectionCache = {};
  static final Map<String, DateTime> _cacheTime = {};

  static bool get isRateLimited =>
      _rateLimitedUntil != null && DateTime.now().isBefore(_rateLimitedUntil!);

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

  void _handleStatusCode(int code, [String? body]) {
    lastStatusCode = code;
    if (code == 429) {
      _rateLimitedUntil = DateTime.now().add(const Duration(seconds: 20));
      if (body != null && (body.contains('RESOURCE_EXHAUSTED') || body.contains('Quota exceeded'))) {
        lastErrorMessage = 'RESOURCE_EXHAUSTED';
      }
    } else if (code == 200 || code == 201 || code == 204) {
      if (isRateLimited) _rateLimitedUntil = null;
      lastErrorMessage = null;
    }
  }

  /// Fetch a single document
  Future<Map<String, dynamic>?> getDocument(String collection, String docId, {bool bypassBackoff = false}) async {
    if (isRateLimited && !bypassBackoff) {
      return null;
    }

    final uri = Uri.parse('$_baseUrl/$collection/$docId$_apiKeyParam');
    try {
      final response = await _client.get(uri, headers: _headers());
      _handleStatusCode(response.statusCode, response.body);
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body) as Map<String, dynamic>;
        return _decodeFirestoreFields(decoded['fields'] as Map<String, dynamic>? ?? {});
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// List all documents in a collection with intelligent caching and backoff
  Future<List<Map<String, dynamic>>> getCollection(String collection) async {
    final now = DateTime.now();

    // Serve from cache if requested recently (within 8 seconds)
    final lastTime = _cacheTime[collection];
    if (lastTime != null && now.difference(lastTime).inSeconds < 8) {
      final cached = _collectionCache[collection];
      if (cached != null) return List.from(cached);
    }

    // If rate-limited, return cached data without hitting API
    if (isRateLimited) {
      final cached = _collectionCache[collection];
      if (cached != null) return List.from(cached);
      return [];
    }

    final uri = Uri.parse('$_baseUrl/$collection$_apiKeyParam');
    try {
      final response = await _client.get(uri, headers: _headers());
      _handleStatusCode(response.statusCode, response.body);
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body) as Map<String, dynamic>;
        final documents = decoded['documents'] as List<dynamic>? ?? [];
        final list = documents.map((doc) {
          final fields = (doc as Map<String, dynamic>)['fields'] as Map<String, dynamic>? ?? {};
          final name = doc['name'] as String? ?? '';
          final docId = name.split('/').last;
          final map = _decodeFirestoreFields(fields);
          map['id'] = docId;
          return map;
        }).toList();

        _collectionCache[collection] = list;
        _cacheTime[collection] = now;
        return list;
      }
      // Return cached fallback if available
      final fallback = _collectionCache[collection];
      if (fallback != null) return List.from(fallback);
      return [];
    } catch (_) {
      final fallback = _collectionCache[collection];
      if (fallback != null) return List.from(fallback);
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
      _handleStatusCode(response.statusCode, response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        // Invalidate cache for this collection
        _cacheTime.remove(collection);
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Delete a document
  Future<bool> deleteDocument(String collection, String docId) async {
    final uri = Uri.parse('$_baseUrl/$collection/$docId$_apiKeyParam');
    try {
      final response = await _client.delete(uri, headers: _headers());
      _handleStatusCode(response.statusCode, response.body);
      if (response.statusCode == 200 || response.statusCode == 204) {
        _cacheTime.remove(collection);
        return true;
      }
      return false;
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
