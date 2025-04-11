import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiBase {
  static const String _baseUrl = 'https://app.tikitar.com/api';

  static const Map<String, String> _defaultHeaders = {
    'Content-Type': 'application/json',
  };

  /// POST request
  static Future<dynamic> post(String endpoint, Map<String, dynamic> body, {String? token}) async {
    final uri = Uri.parse('$_baseUrl$endpoint');
    final headers = {
      ..._defaultHeaders,
      if (token != null) 'Authorization': 'Bearer $token',
    };

    print("POST Uri: $uri");
    print("POST Body: $body");

    final response = await http.post(uri, headers: headers, body: jsonEncode(body));

    if (response.statusCode == 200 ||  response.statusCode == 201) {
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

  /// GET request with optional token
  static Future<dynamic> get(String endpoint, {String? token}) async {
    final uri = Uri.parse('$_baseUrl$endpoint');
    final headers = {
      ..._defaultHeaders,
      if (token != null) 'Authorization': 'Bearer $token',
    };

    print("GET Uri: $uri");
    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
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
}
