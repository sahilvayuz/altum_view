import 'dart:convert';
import 'package:altum_view/core/constants/api_constants.dart';
import 'package:altum_view/core/errors/app_exception.dart';
import 'package:http/http.dart' as http;

class AuthService {
  const AuthService();

  /// Returns access_token string on success, throws [AppException] on failure.
  Future<String> login({
    required String clientId,
    required String clientSecret,
    required String scope,
  }) async {
    final resp = await http.post(
      Uri.parse(ApiConstants.tokenUrl),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'grant_type':    'client_credentials',
        'client_id':     clientId,
        'client_secret': clientSecret,
        'scope':         scope,
      },
    );

    final body = jsonDecode(resp.body) as Map<String, dynamic>;

    if (resp.statusCode == 200) {
      final token = body['access_token'] as String?;
      if (token == null || token.isEmpty) {
        throw const ApiException('access_token missing in response');
      }
      return token;
    }

    throw ApiException(
      body['error_description'] as String? ??
      body['message']           as String? ??
      'Login failed (${resp.statusCode})',
    );
  }
}
