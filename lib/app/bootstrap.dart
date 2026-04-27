import 'dart:developer';

import 'package:altum_view/core/services/ble_services.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:altum_view/app/app.dart';
import 'package:altum_view/sdk_config.dart';

import 'package:altum_view/features/auth/controller/auth_controller.dart';
import 'package:altum_view/features/auth/service/auth_service.dart';

Future<void> bootstrap({bool sdkMode = false}) async {
  try {
    if (sdkMode) {
      SDKConfig.enableSDK();
    } else {
      SDKConfig.disableSDK();
    }

    runApp(
      MultiProvider(
        providers: [
          Provider<AuthService>(
            create: (_) => const AuthService(),
          ),
          ChangeNotifierProvider<AuthController>(
            create: (context) => AuthController(
              context.read<AuthService>(),
            )..initialize(),
          ),

          // ── BleService lives here so it's available app-wide ───────────────
          Provider<BleService>(
            create: (_) => BleService(),
          ),
        ],
        child: const AltumViewApp(),
      ),
    );
  } catch (error, stack) {
    log('Unhandled error: $error', error: error, stackTrace: stack);
  }
}