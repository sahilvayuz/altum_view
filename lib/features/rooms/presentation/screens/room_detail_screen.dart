// features/rooms/presentation/screens/room_detail_screen.dart

import 'package:altum_view/features/camera/controller/camera_controller.dart';
import 'package:altum_view/features/camera/presentation/screens/camera_detail_screen.dart';
import 'package:altum_view/features/camera/service/models/camera_model.dart';
import 'package:altum_view/features/camera/service/remote_service/camera_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:altum_view/core/design_system/app_theme.dart';
import 'package:altum_view/core/networking/dio_client.dart';
import 'package:altum_view/features/rooms/service/room_model.dart';

class RoomDetailScreen extends StatelessWidget {
  final RoomModel room;
  const RoomDetailScreen({super.key, required this.room});

  @override
  Widget build(BuildContext context) {
    final client = context.read<DioClient>();
    return ChangeNotifierProvider(
      create: (_) => CameraController(CameraService(client))
        ..fetchCameras(room.id),
      child: _RoomDetailPage(room: room),
    );
  }
}

class _RoomDetailPage extends StatelessWidget {
  final RoomModel room;
  const _RoomDetailPage({required this.room});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
              child: Row(
                children: [
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: Row(
                      children: const [
                        Icon(CupertinoIcons.chevron_left,
                            color: AppTheme.primary, size: 18),
                        SizedBox(width: 2),
                        Text('Rooms',
                            style: TextStyle(
                                color: AppTheme.primary, fontSize: 17)),
                      ],
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  _AddDeviceButton(roomId: room.id),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
              child: Text(
                room.name.isEmpty ? 'Unnamed Room' : room.name,
                style: const TextStyle(
                  color:      AppTheme.onBackground,
                  fontSize:   32,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ── Camera list ──────────────────────────────────────────────────
            Expanded(
              child: Consumer<CameraController>(
                builder: (_, ctrl, __) {
                  if (ctrl.status == CameraLoadStatus.loading) {
                    return const Center(
                      child: CircularProgressIndicator(
                          color: AppTheme.primary, strokeWidth: 2),
                    );
                  }

                  if (ctrl.status == CameraLoadStatus.error) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(CupertinoIcons.exclamationmark_triangle,
                                color: AppTheme.onSurfaceSub, size: 36),
                            const SizedBox(height: 12),
                            Text(ctrl.errorMessage ?? 'Failed to load cameras',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    color: AppTheme.onSurfaceSub,
                                    fontSize: 14)),
                            const SizedBox(height: 16),
                            CupertinoButton(
                              child: const Text('Retry',
                                  style: TextStyle(color: AppTheme.primary)),
                              onPressed: () => ctrl.fetchCameras(room.id),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  if (ctrl.cameras.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(CupertinoIcons.camera,
                              color: AppTheme.onSurfaceSub, size: 40),
                          SizedBox(height: 14),
                          Text('No cameras in this room',
                              style: TextStyle(
                                  color: AppTheme.onSurfaceSub, fontSize: 14)),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    color: AppTheme.primary,
                    backgroundColor: AppTheme.surfaceCard,
                    onRefresh: () => ctrl.refresh(room.id),
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      itemCount: ctrl.cameras.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (ctx, i) =>
                          _CameraCard(camera: ctrl.cameras[i]),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Add Device button ─────────────────────────────────────────────────────────

class _AddDeviceButton extends StatelessWidget {
  final int roomId;
  const _AddDeviceButton({required this.roomId});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // TODO: open BLE pairing flow, pass roomId
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(CupertinoIcons.add, color: AppTheme.primary, size: 16),
            SizedBox(width: 6),
            Text('Add Device',
                style: TextStyle(
                  color:      AppTheme.primary,
                  fontSize:   14,
                  fontWeight: FontWeight.w600,
                )),
          ],
        ),
      ),
    );
  }
}

// ── Camera card ───────────────────────────────────────────────────────────────

class _CameraCard extends StatelessWidget {
  final CameraModel camera;
  const _CameraCard({required this.camera});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CameraDetailScreen(camera: camera),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ── Top row ──────────────────────────────────────────────────
            Row(
              children: [
                // Camera icon
                Container(
                  width: 46, height: 46,
                  decoration: BoxDecoration(
                    color: AppTheme.success.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(CupertinoIcons.camera_fill,
                      color: AppTheme.success, size: 22),
                ),
                const SizedBox(width: 12),

                // Name + serial
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        camera.friendlyName.isEmpty
                            ? camera.serialNumber
                            : camera.friendlyName,
                        style: const TextStyle(
                          color:      AppTheme.onSurface,
                          fontSize:   15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        camera.serialNumber,
                        style: const TextStyle(
                            color:    AppTheme.onSurfaceSub,
                            fontSize: 12),
                      ),
                    ],
                  ),
                ),

                // Online badge
                _OnlineBadge(online: camera.isOnline),
              ],
            ),

            const SizedBox(height: 12),
            Divider(
                color: Colors.white.withOpacity(0.06), height: 1),
            const SizedBox(height: 12),

            // ── Bottom row — Wi-Fi / firmware / Details ───────────────────
            Row(
              children: [
                const Icon(CupertinoIcons.wifi,
                    color: AppTheme.onSurfaceSub, size: 13),
                const SizedBox(width: 4),
                Text(camera.wifiSsid,
                    style: const TextStyle(
                        color: AppTheme.onSurfaceSub, fontSize: 12)),
                const SizedBox(width: 16),
                const Icon(CupertinoIcons.info_circle,
                    color: AppTheme.onSurfaceSub, size: 13),
                const SizedBox(width: 4),
                Text(camera.firmware,
                    style: const TextStyle(
                        color: AppTheme.onSurfaceSub, fontSize: 12)),
                const Spacer(),
                Text('Details',
                    style: TextStyle(
                        color: AppTheme.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
                const SizedBox(width: 2),
                const Icon(CupertinoIcons.chevron_right,
                    color: AppTheme.primary, size: 13),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Online badge ──────────────────────────────────────────────────────────────

class _OnlineBadge extends StatelessWidget {
  final bool online;
  const _OnlineBadge({required this.online});

  @override
  Widget build(BuildContext context) {
    final color = online ? AppTheme.success : AppTheme.onSurfaceSub;
    final label = online ? 'Online' : 'Offline';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 6, height: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(
                  color: color, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}