// lib/bootstrap.dart

import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:altum_view/app/app.dart';
import 'package:altum_view/features/auth/controller/auth_controller.dart';
import 'package:altum_view/features/auth/service/auth_service.dart';

void bootstrap() {
  runZonedGuarded(
        () async {
      WidgetsFlutterBinding.ensureInitialized();

      runApp(
        MultiProvider(
          providers: [
            /// Global auth service
            Provider<AuthService>(
              create: (_) => const AuthService(),
            ),

            /// Global auth state
            ChangeNotifierProvider<AuthController>(
              create: (context) => AuthController(
                context.read<AuthService>(),
              ),
            ),
          ],
          child: const AltumViewApp(),
        ),
      );
    },
        (error, stack) {
      log(
        'Unhandled error: $error',
        error: error,
        stackTrace: stack,
      );
    },
  );
}