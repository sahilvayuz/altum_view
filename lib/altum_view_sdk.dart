library altum_view_sdk;

import 'package:altum_view/app/bootstrap.dart';
import 'package:altum_view/core/networking/dio_client.dart';
import 'package:altum_view/core/services/ble_services.dart';
import 'package:altum_view/features/auth/service/auth_service.dart';
import 'package:altum_view/features/device_connection/controller/device_connection_controller.dart';
import 'package:altum_view/features/device_connection/controller/wifi_controller.dart';
import 'package:altum_view/features/device_connection/service/device_connection_service.dart';
import 'package:altum_view/features/device_connection/service/wifi_service.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';

// ── Connection-phase screen exports (used by host app) ───────────────────────
export 'package:altum_view/features/device_connection/presentation/screens/device_connection_screen.dart';
export 'package:altum_view/features/device_connection/presentation/screens/device_name_screen.dart';
export 'package:altum_view/features/device_connection/presentation/screens/wifi_provision_screen.dart';

class AltumViewSDK {
  AltumViewSDK._();

  static DioClient? _client;
  static BleService? _ble;
  static bool _embedded = false;

  static const _storage = FlutterSecureStorage();

  static const _tokenKey    = 'altum_sdk_token';
  static const _loggedInKey = 'altum_sdk_loggedin';

  static bool get isEmbedded => _embedded;
  static bool get isReady    => _client != null;
  static bool get isLoggedIn => _client != null;

  static DioClient get client {
    if (_client == null) throw Exception('SDK not initialized — call login() first');
    return _client!;
  }

  // ── Internal BLE accessor (used by wrapConnectionProviders) ───────────────
  static BleService get _bleService {
    _ble ??= BleService();
    return _ble!;
  }

  // ---------------------------------------------------------------------------
  // INITIALIZE
  // ---------------------------------------------------------------------------
  static Future<void> initialize({required bool embeddedMode}) async {
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

  // ---------------------------------------------------------------------------
  // LOGIN
  // ---------------------------------------------------------------------------
  static Future<void> login({
    required String clientId,
    required String clientSecret,
    required String scope,
  }) async {
    final auth  = const AuthService();
    final token = await auth.login(
      clientId:     clientId,
      clientSecret: clientSecret,
      scope:        scope,
    );

    await _storage.write(key: _tokenKey,    value: token);
    await _storage.write(key: _loggedInKey, value: 'true');

    _client = DioClient(accessToken: token);
  }

  // ---------------------------------------------------------------------------
  // CHECK LOGIN STATE
  // ---------------------------------------------------------------------------
  static Future<bool> hasLoggedInBefore() async {
    final value = await _storage.read(key: _loggedInKey);
    return value == 'true';
  }

  // ---------------------------------------------------------------------------
  // LOGOUT
  // ---------------------------------------------------------------------------
  static Future<void> logout() async {
    _client = null;
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _loggedInKey);
  }

  // ---------------------------------------------------------------------------
  // WRAP CONNECTION PROVIDERS
  //
  // Wrap your connection-phase entry point (e.g. BluetoothScanScreen) with
  // this so DeviceConnectionController and WifiController are available to the
  // full screen stack without any Provider already needing to exist in the
  // host app's tree.
  //
  // Usage:
  //   AltumViewSDK.wrapConnectionProviders(child: BluetoothScanScreen(room: room))
  // ---------------------------------------------------------------------------
  static Widget wrapConnectionProviders({required Widget child}) {
    if (_client == null) throw Exception('SDK not logged in — call login() first');

    final client = _client!;
    final ble    = _bleService;

    return MultiProvider(
      providers: [
        Provider<DeviceConnectionService>(
          create: (_) => DeviceConnectionService(ble: ble, client: client),
        ),
        ChangeNotifierProvider<DeviceConnectionController>(
          create: (ctx) => DeviceConnectionController(
            ctx.read<DeviceConnectionService>(),
          ),
        ),
        Provider<WifiService>(
          create: (_) => WifiService(ble),
        ),
        ChangeNotifierProvider<WifiController>(
          create: (ctx) => WifiController(ctx.read<WifiService>()),
        ),
      ],
      child: child,
    );
  }
}