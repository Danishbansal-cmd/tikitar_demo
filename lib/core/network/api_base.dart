import 'dart:convert';
import 'package:http/http.dart' as http;

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
    print("API token set: $_token");
  }

  /// POST request
  static Future<dynamic> post(String endpoint, Map<String, dynamic> body, {String? token}) async {
    final uri = Uri.parse('$_baseUrl$endpoint');
    final authToken = token ?? _token;

    final headers = {
      ..._defaultHeaders,
      if (authToken != null) 'Authorization': 'Bearer $authToken',
    };

    print("POST Uri: $uri");
    print("POST Body: $body");
    print("POST headers: $headers");

    final response = await http.post(uri, headers: headers, body: jsonEncode(body));

    if (response.statusCode == 200 || response.statusCode == 201) {
      try {
        final decoded = jsonDecode(response.body);
        print("POST response decoded: $decoded");
        return decoded;
      } catch (e) {
        print("POST JSON Decode Error: $e");
        throw Exception('Invalid JSON response');
      }
    } else {
      print("POST Error: ${response.statusCode} - ${response.body}");
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

    print("GET Uri: $uri");
    print("GET headers: $headers");

    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      print("Raw response from get body: ${response.body}");
      print("Raw response from get statusCode: ${response.statusCode}");
      try {
        final decoded = jsonDecode(response.body);
        print("GET response decoded: $decoded");
        return decoded;
      } catch (e) {
        print("GET JSON Decode Error: $e");
        throw Exception('Invalid JSON response');
      }
    } else {
      print("GET Error: ${response.statusCode} - ${response.body}");
      throw Exception('Failed to GET: ${response.statusCode}');
    }
  }
}
