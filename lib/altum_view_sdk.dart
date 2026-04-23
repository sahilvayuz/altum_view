// lib/altum_view_sdk.dart

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
  static Widget wrapProviders({
    required Widget child,
  }) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(
          create: (_) => const AuthService(),
        ),

        ChangeNotifierProvider<AuthController>(
          create: (context) => AuthController(
            context.read<AuthService>(),
          )..initialize(),
        ),

        if (isLoggedIn)
          Provider<DioClient>.value(
            value: client,
          ),

        if (isLoggedIn)
          Provider<RoomService>(
            create: (_) => RoomService(client),
          ),

        if (isLoggedIn)
          ChangeNotifierProvider<RoomController>(
            create: (context) => RoomController(
              context.read<RoomService>(),
            )..fetchRooms(),
          ),

        if (isLoggedIn)
          Provider<CameraService>(
            create: (_) => CameraService(client),
          ),

        if (isLoggedIn)
          ChangeNotifierProvider<CameraController>(
            create: (context) => CameraController(
              context.read<CameraService>(),
            ),
          ),
      ],
      child: child,
    );
  }
}