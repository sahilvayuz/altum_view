import 'package:altum_view/features/auth/service/auth_service.dart';
import 'package:flutter/foundation.dart';

enum AuthStatus { idle, loading, success, error }

class AuthController extends ChangeNotifier {
  AuthController(this._service);

  final AuthService _service;

  AuthStatus _status = AuthStatus.idle;
  String?    _token;
  String?    _error;

  AuthStatus get status => _status;
  String?    get token  => _token;
  String?    get error  => _error;
  bool       get isLoading => _status == AuthStatus.loading;

  Future<bool> login({
    required String clientId,
    required String clientSecret,
    required String scope,
  }) async {
    _status = AuthStatus.loading;
    _error  = null;
    notifyListeners();

    try {
      _token  = await _service.login(
        clientId:     clientId,
        clientSecret: clientSecret,
        scope:        scope,
      );
      _status = AuthStatus.success;
      notifyListeners();
      return true;
    } catch (e) {
      _status = AuthStatus.error;
      _error  = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  void signOut() {
    _token  = null;
    _status = AuthStatus.idle;
    _error  = null;
    notifyListeners();
  }
}
