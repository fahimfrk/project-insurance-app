import 'dart:convert';
import 'package:http/http.dart' as http;

class DirectusService {
  static const String baseUrl = 'http://192.168.1.47:8055';

  static String? accessToken;

  // LOGIN
  static Future<bool> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);

      accessToken = json['data']['access_token'];

      return true;
    }

    return false;
  }

  // REGISTER
  static Future<bool> register({
    required String username,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/items/agent'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );

    print('Register status: ${response.statusCode}');
    print('Register response: ${response.body}');

    return response.statusCode == 200 || response.statusCode == 201;
  }

  // LOGOUT
  static Future<void> logout() async {
    if (accessToken == null) return;

    await http.post(
      Uri.parse('$baseUrl/auth/logout'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'refresh_token': accessToken}),
    );

    accessToken = null;
  }
}
