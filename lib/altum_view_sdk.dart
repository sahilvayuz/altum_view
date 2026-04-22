// // lib/altum_view_sdk.dart
//
// library altum_view_sdk;
//
// /// ------------------------------------------------------------
// /// CORE STARTUP
// /// ------------------------------------------------------------
//
// export 'app/bootstrap.dart';
// export 'sdk_config.dart';
//
// /// ------------------------------------------------------------
// /// AUTH
// /// ------------------------------------------------------------
//
// export 'features/auth/presentation/screens/login_screen.dart';
//
// /// ------------------------------------------------------------
// /// ROOMS
// /// ------------------------------------------------------------
//
// export 'features/rooms/presentation/screens/rooms_screen.dart';
// export 'features/rooms/presentation/screens/room_detail_screen.dart';
//
// /// ------------------------------------------------------------
// /// CAMERA
// /// ------------------------------------------------------------
//
// export 'features/camera/presentation/screens/camera_detail_screen.dart';
//
// /// ------------------------------------------------------------
// /// SKELETON STREAM
// /// ------------------------------------------------------------
//
// export 'features/skeleton_stream/presentation/screens/skeleton_stream_screen.dart';
//
// /// ------------------------------------------------------------
// /// CONTROLLERS (Optional for advanced integrations)
// /// ------------------------------------------------------------
//
// export 'features/auth/controller/auth_controller.dart';
// export 'features/rooms/controller/room_controller.dart';
// export 'features/camera/controller/camera_controller.dart';
// export 'features/skeleton_stream/controller/skeleton_stream_controller.dart';
//
// /// ------------------------------------------------------------
// /// SERVICES (Optional for custom usage)
// /// ------------------------------------------------------------
//
// export 'features/auth/service/auth_service.dart';
// export 'features/rooms/service/room_service.dart';
// export 'features/camera/service/remote_service/camera_service.dart';
// export 'features/skeleton_stream/service/remote_service/skeleton_stream_service.dart';


library altum_view_sdk;

import 'package:flutter/material.dart';

import 'package:altum_view/app/bootstrap.dart';
import 'package:altum_view/core/networking/dio_client.dart';
import 'package:altum_view/features/auth/service/auth_service.dart';

export 'features/rooms/presentation/screens/rooms_screen.dart';
export 'features/rooms/presentation/screens/room_detail_screen.dart';
export 'features/camera/presentation/screens/camera_detail_screen.dart';
export 'features/skeleton_stream/presentation/screens/skeleton_stream_screen.dart';

class AltumViewSDK {
  AltumViewSDK._();

  static DioClient? _client;
  static bool _embedded = false;

  static bool get isEmbedded =>
      _embedded;

  static bool get isReady =>
      _client != null;

  static DioClient get client {
    if (_client == null) {
      throw Exception(
        'SDK not initialized',
      );
    }

    return _client!;
  }

  /// --------------------------------------------------
  /// BOOL MODE CONFIG
  /// --------------------------------------------------
  static Future<void> configure({
    required bool embeddedMode,
    required String clientId,
    required String clientSecret,
    required String scope,
  }) async {
    _embedded = embeddedMode;

    /// HOST APP MODE
    if (_embedded) {
      final auth =
      const AuthService();

      final token =
      await auth.login(
        clientId: clientId,
        clientSecret:
        clientSecret,
        scope: scope,
      );

      _client = DioClient(
        accessToken: token,
      );

      return;
    }

    /// FULL APP MODE
    bootstrap(
      sdkMode: true,
      clientId: clientId,
      clientSecret:
      clientSecret,
      scope: scope,
    );
  }

  static void logout() {
    _client = null;
  }
}