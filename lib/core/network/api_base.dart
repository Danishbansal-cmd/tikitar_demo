import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:developer' as developer;

class ApiBase {
  static const String _baseUrl = 'https://app.tikitar.com/api';

  /// Getter to access the base URL
  static String get baseUrl => _baseUrl;

  static const Map<String, String> _defaultHeaders = {
    'Content-Type': 'application/json',
  };

  static String? _token; // Global token variable

  /// Call this once when the app starts
  static void setToken(String token) {
    _token = token;
    developer.log("APIBASE setting token: $_token", name: 'ApiBase');
  }

  /// POST request
  static Future<dynamic> post(
    String endpoint,
    Map<String, dynamic> body, {
    String? token,
  }) async {
    final uri = Uri.parse('$_baseUrl$endpoint');
    final authToken = token ?? _token;

    final headers = {
      ..._defaultHeaders,
      if (authToken != null) 'Authorization': 'Bearer $authToken',
    };

    developer.log("POST Uri: $uri", name: 'ApiBase');
    developer.log("POST Body: $body", name: 'ApiBase');
    developer.log("POST headers: $headers", name: 'ApiBase');

    final response = await http.post(
      uri,
      headers: headers,
      body: jsonEncode(body),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      try {
        final decoded = jsonDecode(response.body);
        developer.log("POST response decoded: $decoded", name: 'ApiBase');
        return decoded;
      } catch (e) {
        developer.log("POST JSON Decode Error: $e", name: 'ApiBase');
        throw Exception('Invalid JSON response');
      }
    } else {
      developer.log(
        "POST Error: ${response.statusCode} - ${response.body}",
        name: 'ApiBase',
      );
      throw Exception('Failed to POST: ${response.statusCode}');
    }
  }

  /// GET request
  static Future<dynamic> get(String endpoint, {String? token}) async {
    final uri = Uri.parse('$_baseUrl$endpoint');
    final authToken = token ?? _token;

    final headers = {
      ..._defaultHeaders,
      if (authToken != null) 'Authorization': 'Bearer $authToken',
    };

    developer.log("GET Uri: $uri", name: 'ApiBase');
    developer.log("GET headers: $headers", name: 'ApiBase');

    final response = await http.get(uri, headers: headers);
    developer.log("GET $endpoint: ${response.body}", name: 'ApiBase');
    developer.log("GET $endpoint: ${response.statusCode}", name: 'ApiBase');

    if (response.statusCode == 200) {
      try {
        final decoded = jsonDecode(response.body);
        developer.log("GET response decoded: $decoded", name: 'ApiBase');
        return decoded;
      } catch (e) {
        developer.log("GET JSON Decode Error: $e", name: 'ApiBase', error: e);
        throw Exception('Invalid JSON response');
      }
    } else {
      throw Exception('Failed to GET: ${response.statusCode}');
    }
  }

  /// POST MULTIPART Data
  static Future<dynamic> multipartPost(
    String endpoint,
    Map<String, String> body,
    String filedataKey,
    File filedata, {
    String? token,
  }) async {
    final uri = Uri.parse('$_baseUrl$endpoint');
    final authToken = token ?? _token;

    final request =
        http.MultipartRequest('POST', uri)
          ..headers['Authorization'] = 'Bearer $authToken'
          ..fields.addAll(body);

    final file = await http.MultipartFile.fromPath(filedataKey, filedata.path);
    request.files.add(file);

    developer.log("multipartPost Uri: $uri", name: 'ApiBase');
    developer.log("multipartPost Body: $body", name: 'ApiBase');
    developer.log("multipartPost request: $request", name: 'ApiBase');

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();
    developer.log("multipartPost $endpoint: $responseBody", name: 'ApiBase');
    developer.log("multipartPost $endpoint: ${response.statusCode}", name: 'ApiBase');

    if (response.statusCode == 200 || response.statusCode == 201) {
      return responseBody;
    } else {
      developer.log(
        "multipartPost Error: ${response.statusCode} - $responseBody",
        name: 'ApiBase',
      );
      throw Exception('Failed to multipartPost: ${response.statusCode}');
    }
  }
}
