import 'package:altum_view/core/services/ble_services.dart';
import 'package:altum_view/features/device_connection/controller/device_connection_controller.dart';
import 'package:altum_view/features/device_connection/controller/wifi_controller.dart';
import 'package:altum_view/features/device_connection/service/device_connection_service.dart';
import 'package:altum_view/features/device_connection/service/wifi_service.dart';
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

    // ── Logged in ──────────────────────────────────────────────────────────
    if (auth.status == AuthStatus.success && auth.token != null) {
      final client = DioClient(accessToken: auth.token!);
      final ble    = context.read<BleService>();

      return MultiProvider(
        providers: [
          Provider<DioClient>.value(value: client),

          Provider<RoomService>(
            create: (_) => RoomService(client),
          ),
          ChangeNotifierProvider<RoomController>(
            create: (ctx) => RoomController(ctx.read<RoomService>())..fetchRooms(),
          ),

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
        child: const _AuthenticatedApp(),
      );
    }

    // ── Loading ────────────────────────────────────────────────────────────
    if (auth.status == AuthStatus.loading) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        home: const Scaffold(
          backgroundColor: AppTheme.background,
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    // ── Error ──────────────────────────────────────────────────────────────
    if (auth.status == AuthStatus.error) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        home: Scaffold(
          backgroundColor: AppTheme.background,
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                auth.error ?? 'Login Failed',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red, fontSize: 16),
              ),
            ),
          ),
        ),
      );
    }

    // ── Default = login ────────────────────────────────────────────────────
    return const _UnauthenticatedApp();
  }
}

// ── Login app ─────────────────────────────────────────────────────────────────

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

// ── Authenticated app ─────────────────────────────────────────────────────────

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

// ── Main shell ────────────────────────────────────────────────────────────────

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
          const _PlaceholderScreen('Alerts',  CupertinoIcons.bell_fill),
          const _PlaceholderScreen('People',  CupertinoIcons.person_2_fill),
          _AccountScreen(onSignOut: () => context.read<AuthController>().signOut()),
        ],
      ),
      bottomNavigationBar: _BottomNav(
        selected: _tab,
        onTap: (i) => setState(() => _tab = i),
      ),
    );
  }
}

// ── Bottom nav ────────────────────────────────────────────────────────────────

class _BottomNav extends StatelessWidget {
  final int                selected;
  final ValueChanged<int>  onTap;

  const _BottomNav({required this.selected, required this.onTap});

  static const _items = [
    (CupertinoIcons.house_fill,             'Rooms'),
    (CupertinoIcons.bell_fill,              'Alerts'),
    (CupertinoIcons.person_2_fill,          'People'),
    (CupertinoIcons.person_crop_circle_fill,'Account'),
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
            children: List.generate(_items.length, (i) {
              final active = selected == i;
              final item   = _items[i];
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(item.$1,
                          color: active ? AppTheme.primary : AppTheme.onSurfaceSub),
                      const SizedBox(height: 4),
                      Text(
                        item.$2,
                        style: TextStyle(
                          fontSize:   10,
                          fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                          color:      active ? AppTheme.primary : AppTheme.onSurfaceSub,
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

// ── Placeholder ───────────────────────────────────────────────────────────────

class _PlaceholderScreen extends StatelessWidget {
  final String   title;
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
            Icon(icon, size: 48, color: AppTheme.onSurfaceSub),
            const SizedBox(height: 12),
            Text(title,
                style: const TextStyle(
                  color:      AppTheme.onSurface,
                  fontSize:   20,
                  fontWeight: FontWeight.w700,
                )),
            const SizedBox(height: 6),
            const Text('Coming soon',
                style: TextStyle(color: AppTheme.onSurfaceSub)),
          ],
        ),
      ),
    );
  }
}

// ── Account ───────────────────────────────────────────────────────────────────

class _AccountScreen extends StatelessWidget {
  final VoidCallback onSignOut;

  const _AccountScreen({required this.onSignOut});

  @override
  Widget build(BuildContext context) {
    final token      = context.watch<AuthController>().token ?? '';
    final shortToken = token.length > 20 ? '${token.substring(0, 20)}…' : token;

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
                  color:      AppTheme.onBackground,
                  fontSize:   30,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 24),
              Text('Token: $shortToken',
                  style: const TextStyle(color: AppTheme.onSurfaceSub)),
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