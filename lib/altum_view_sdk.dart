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


/***
 * // lib/altum_view_sdk.dart

    library altum_view_sdk;

    import 'package:flutter/material.dart';
    import 'package:provider/provider.dart';

    import 'package:altum_view/app/bootstrap.dart';
    import 'package:altum_view/core/networking/dio_client.dart';

    import 'package:altum_view/features/auth/controller/auth_controller.dart';
    import 'package:altum_view/features/auth/service/auth_service.dart';

    import 'package:altum_view/features/rooms/controller/room_controller.dart';
    import 'package:altum_view/features/rooms/service/room_service.dart';

    import 'package:altum_view/features/camera/controller/camera_controller.dart';
    import 'package:altum_view/features/camera/service/remote_service/camera_service.dart';

    export 'features/rooms/presentation/screens/rooms_screen.dart';
    export 'features/rooms/presentation/screens/room_detail_screen.dart';
    export 'features/camera/presentation/screens/camera_detail_screen.dart';
    export 'features/skeleton_stream/presentation/screens/skeleton_stream_screen.dart';

    class AltumViewSDK {
    AltumViewSDK._();

    static DioClient? _client;
    static bool _embedded = false;

    static bool get isEmbedded => _embedded;

    static bool get isReady => true;

    static bool get isLoggedIn => _client != null;

    static DioClient get client {
    if (_client == null) {
    throw Exception(
    'AltumViewSDK not logged in. Call login() first.',
    );
    }

    return _client!;
    }

    /// ------------------------------------------------------
    /// INIT
    /// ------------------------------------------------------
    static Future<void> initialize({
    required bool embeddedMode,
    }) async {
    _embedded = embeddedMode;

    if (!_embedded) {
    await bootstrap(
    sdkMode: true,
    );
    }
    }

    /// ------------------------------------------------------
    /// LOGIN
    /// ------------------------------------------------------
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

    _client = DioClient(
    accessToken: token,
    );
    }

    /// ------------------------------------------------------
    /// LOGOUT
    /// ------------------------------------------------------
    static Future<void> logout() async {
    _client = null;
    }

    /// ------------------------------------------------------
    /// HOST APP WRAPPER
    /// ------------------------------------------------------
    // static Widget wrapProviders({required Widget child,}) {
    //   return MultiProvider(
    //     providers: [
    //       Provider<AuthService>(
    //         create: (_) => const AuthService(),
    //       ),
    //
    //       ChangeNotifierProvider<AuthController>(
    //         create: (context) => AuthController(
    //           context.read<AuthService>(),
    //         )..initialize(),
    //       ),
    //
    //       if (isLoggedIn)
    //         Provider<DioClient>.value(
    //           value: client,
    //         ),
    //
    //       if (isLoggedIn)
    //         Provider<RoomService>(
    //           create: (_) => RoomService(client),
    //         ),
    //
    //       if (isLoggedIn)
    //         ChangeNotifierProvider<RoomController>(
    //           create: (context) => RoomController(
    //             context.read<RoomService>(),
    //           )..fetchRooms(),
    //         ),
    //
    //       if (isLoggedIn)
    //         Provider<CameraService>(
    //           create: (_) => CameraService(client),
    //         ),
    //
    //       if (isLoggedIn)
    //         ChangeNotifierProvider<CameraController>(
    //           create: (context) => CameraController(
    //             context.read<CameraService>(),
    //           ),
    //         ),
    //     ],
    //     child: child,
    //   );
    // }
    }
 */