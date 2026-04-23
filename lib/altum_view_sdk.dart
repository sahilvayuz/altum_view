library altum_view_sdk;

import 'package:altum_view/app/bootstrap.dart';
import 'package:altum_view/core/networking/dio_client.dart';
import 'package:altum_view/features/auth/service/auth_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AltumViewSDK {
  AltumViewSDK._();

  static DioClient? _client;
  static bool _embedded = false;

  static const _storage = FlutterSecureStorage();

  static const _tokenKey = 'altum_sdk_token';
  static const _loggedInKey = 'altum_sdk_loggedin';

  static bool get isEmbedded => _embedded;
  static bool get isReady => _client != null;
  static bool get isLoggedIn => _client != null;

  static DioClient get client {
    if (_client == null) {
      throw Exception('SDK not initialized');
    }
    return _client!;
  }

  /// -----------------------------------------
  /// ONLY INITIALIZE SDK
  /// -----------------------------------------
  static Future<void> initialize({
    required bool embeddedMode,
  }) async {
    _embedded = embeddedMode;

    if (_embedded) {
      final token = await _storage.read(key: _tokenKey);

      if (token != null && token.isNotEmpty) {
        _client = DioClient(accessToken: token);
      }

      return;
    }

    bootstrap(sdkMode: true);
  }

  /// -----------------------------------------
  /// LOGIN FROM HOST APP SIGNIN PAGE
  /// -----------------------------------------
  static Future<void> login({
    required String clientId,
    required String clientSecret,
    required String scope,
  }) async {
    final auth = const AuthService();

    final token = await auth.login(
      clientId: clientId,
      clientSecret: clientSecret,
      scope: scope,
    );

    await _storage.write(key: _tokenKey, value: token);
    await _storage.write(key: _loggedInKey, value: 'true');

    _client = DioClient(accessToken: token);
  }

  /// -----------------------------------------
  /// CHECK LOGIN STATE
  /// -----------------------------------------
  static Future<bool> hasLoggedInBefore() async {
    final value = await _storage.read(key: _loggedInKey);
    return value == 'true';
  }

  /// -----------------------------------------
  /// LOGOUT
  /// -----------------------------------------
  static Future<void> logout() async {
    _client = null;

    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _loggedInKey);
  }
}