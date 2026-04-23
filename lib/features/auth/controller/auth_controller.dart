import 'package:flutter/foundation.dart';
import 'package:altum_view/core/storage/auth_token_storage.dart';
import '../service/auth_service.dart';

enum AuthStatus { idle, loading, success, error }

class AuthController extends ChangeNotifier {
  AuthController(this._service);

  final AuthService _service;

  AuthStatus _status = AuthStatus.idle;
  String? _token;
  String? _error;

  AuthStatus get status => _status;
  String? get token => _token;
  String? get error => _error;

  bool get isLoading => _status == AuthStatus.loading;
  bool get isLoggedIn => _token != null;

  Future<void> initialize() async {
    final savedToken = await AuthStorage.getToken();

    if (savedToken != null && savedToken.isNotEmpty) {
      _token = savedToken;
      _error = null;
      _status = AuthStatus.success;
      notifyListeners();
    }
  }

  Future<bool> login({
    required String clientId,
    required String clientSecret,
    required String scope,
  }) async {
    _status = AuthStatus.loading;
    _error = null;
    notifyListeners();

    try {
      final token = await _service.login(
        clientId: clientId,
        clientSecret: clientSecret,
        scope: scope,
      );

      _token = token;
      _error = null;

      await AuthStorage.saveToken(token);

      _status = AuthStatus.success;
      notifyListeners();
      return true;
    } catch (e) {
      _token = null;
      _status = AuthStatus.error;
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    _token = null;
    _error = null;
    _status = AuthStatus.idle;

    await AuthStorage.clear();

    notifyListeners();
  }
}