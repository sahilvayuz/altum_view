// lib/app/app.dart

import 'package:altum_view/features/skeleton_stream/controller/skeleton_stream_controller.dart';
import 'package:altum_view/features/skeleton_stream/service/remote_service/skeleton_stream_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:altum_view/core/design_system/app_theme.dart';
import 'package:altum_view/core/networking/dio_client.dart';

import 'package:altum_view/features/auth/controller/auth_controller.dart';
import 'package:altum_view/features/auth/presentation/screens/login_screen.dart';

import 'package:altum_view/features/rooms/controller/room_controller.dart';
import 'package:altum_view/features/rooms/presentation/screens/rooms_screen.dart';
import 'package:altum_view/features/rooms/service/room_service.dart';

class AltumViewApp extends StatelessWidget {
  const AltumViewApp({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();

    /// Logged in → build authenticated provider tree ABOVE MaterialApp
    if (auth.status == AuthStatus.success && auth.token != null) {
      final client = DioClient(accessToken: auth.token!);

      return MultiProvider(
        providers: [
          /// Global authenticated API client
          Provider<DioClient>.value(value: client),

          /// Rooms feature
          Provider<RoomService>(
            create: (_) => RoomService(client),
          ),

          ChangeNotifierProvider<RoomController>(
            create: (context) => RoomController(
              context.read<RoomService>(),
            )..fetchRooms(),
          ),

          ChangeNotifierProvider<SkeletonStreamController>(
            create: (context) => SkeletonStreamController(
              context.read<SkeletonStreamService>(),
            )
          )
        ],
        child: const _AuthenticatedApp(),
      );
    }

    /// Logged out
    return const _UnauthenticatedApp();
  }
}

/// ---------------------------------------------------------------------------
/// Logged Out App
/// ---------------------------------------------------------------------------

class _UnauthenticatedApp extends StatelessWidget {
  const _UnauthenticatedApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const LoginScreen(),
    );
  }
}

/// ---------------------------------------------------------------------------
/// Logged In App
/// ---------------------------------------------------------------------------

class _AuthenticatedApp extends StatelessWidget {
  const _AuthenticatedApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const _MainShell(),
    );
  }
}

/// ---------------------------------------------------------------------------
/// Main Shell
/// ---------------------------------------------------------------------------

class _MainShell extends StatefulWidget {
  const _MainShell();

  @override
  State<_MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<_MainShell> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: IndexedStack(
        index: _tab,
        children: [
          const RoomsScreen(),
          const _PlaceholderScreen(
            'Alerts',
            CupertinoIcons.bell_fill,
          ),
          const _PlaceholderScreen(
            'People',
            CupertinoIcons.person_2_fill,
          ),
          _AccountScreen(
            onSignOut: () {
              context.read<AuthController>().signOut();
            },
          ),
        ],
      ),
      bottomNavigationBar: _BottomNav(
        selected: _tab,
        onTap: (index) {
          setState(() => _tab = index);
        },
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// Bottom Nav
/// ---------------------------------------------------------------------------

class _BottomNav extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onTap;

  const _BottomNav({
    required this.selected,
    required this.onTap,
  });

  static const items = [
    (CupertinoIcons.house_fill, 'Rooms'),
    (CupertinoIcons.bell_fill, 'Alerts'),
    (CupertinoIcons.person_2_fill, 'People'),
    (CupertinoIcons.person_crop_circle_fill, 'Account'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.surfaceCard,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: List.generate(items.length, (i) {
              final active = selected == i;
              final (icon, label) = items[i];

              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        icon,
                        size: 22,
                        color: active
                            ? AppTheme.primary
                            : AppTheme.onSurfaceSub,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: active
                              ? FontWeight.w700
                              : FontWeight.w400,
                          color: active
                              ? AppTheme.primary
                              : AppTheme.onSurfaceSub,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// Placeholder
/// ---------------------------------------------------------------------------

class _PlaceholderScreen extends StatelessWidget {
  final String title;
  final IconData icon;

  const _PlaceholderScreen(this.title, this.icon);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 48,
              color: AppTheme.onSurfaceSub,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                color: AppTheme.onSurface,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Coming soon',
              style: TextStyle(
                color: AppTheme.onSurfaceSub,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// Account
/// ---------------------------------------------------------------------------

class _AccountScreen extends StatelessWidget {
  final VoidCallback onSignOut;

  const _AccountScreen({
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    final token = context.watch<AuthController>().token ?? '';

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Account',
                style: TextStyle(
                  color: AppTheme.onBackground,
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Token: ${token.length > 20 ? '${token.substring(0, 20)}...' : token}',
                style: const TextStyle(
                  color: AppTheme.onSurfaceSub,
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: onSignOut,
                  child: const Text('Sign Out'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}