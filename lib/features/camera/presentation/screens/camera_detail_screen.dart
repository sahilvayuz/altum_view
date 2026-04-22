// features/cameras/presentation/screens/camera_detail_screen.dart

import 'package:altum_view/features/camera/service/models/camera_model.dart';
import 'package:altum_view/features/skeleton_stream/presentation/screens/skeleton_stream_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:altum_view/core/design_system/app_theme.dart';

class CameraDetailScreen extends StatelessWidget {
  final CameraModel camera;
  const CameraDetailScreen({super.key, required this.camera});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ── Back ──────────────────────────────────────────────────────
              Align(
                alignment: Alignment.centerLeft,
                child: CupertinoButton(
                  padding: EdgeInsets.zero,
                  child: const Icon(CupertinoIcons.chevron_left,
                      color: AppTheme.primary, size: 26),
                  onPressed: () => Navigator.pop(context),
                ),
              ),

              const SizedBox(height: 12),

              // ── Camera icon ───────────────────────────────────────────────
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end:   Alignment.bottomRight,
                    colors: [
                      const Color(0xFF1A3A6B),
                      AppTheme.primary.withOpacity(0.4),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(CupertinoIcons.camera_fill,
                    color: AppTheme.primary, size: 38),
              ),

              const SizedBox(height: 10),

              // ── Online badge ──────────────────────────────────────────────
              _OnlinePill(online: camera.isOnline),

              const SizedBox(height: 8),

              // ── Serial number as title ────────────────────────────────────
              Text(
                camera.serialNumber,
                style: const TextStyle(
                  color:      AppTheme.onBackground,
                  fontSize:   22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),

              const SizedBox(height: 20),

              // ── Info card ─────────────────────────────────────────────────
              _InfoCard(camera: camera),

              const SizedBox(height: 28),

              // ── Section label ─────────────────────────────────────────────
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('CAMERA CONTROLS',
                    style: TextStyle(
                      color:      AppTheme.onSurfaceSub,
                      fontSize:   11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    )),
              ),

              const SizedBox(height: 12),

              // ── Controls grid ─────────────────────────────────────────────
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap:     true,
                physics:        const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing:  12,
                childAspectRatio: 1.2,
                children: [
                  _ControlTile(
                    icon:    CupertinoIcons.play_rectangle_fill,
                    label:   'Live View',
                    color:   AppTheme.success,
                    enabled: camera.isOnline,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SkeletonStreamScreen(
                          cameraId:     camera.id,
                          serialNumber: camera.serialNumber,
                        ),
                      ),
                    ),
                  ),
                  _ControlTile(
                    icon:    CupertinoIcons.bell_fill,
                    label:   'Alerts',
                    color:   const Color(0xFFFF9F0A),
                    enabled: false, // coming soon
                    onTap:   () {},
                  ),
                  _ControlTile(
                    icon:    CupertinoIcons.layers_fill,
                    label:   'Calibrate',
                    color:   AppTheme.primary,
                    enabled: false, // coming soon
                    onTap:   () {},
                  ),
                  _ControlTile(
                    icon:    CupertinoIcons.slider_horizontal_3,
                    label:   'Settings',
                    color:   const Color(0xFFBF5AF2),
                    enabled: false, // coming soon
                    onTap:   () {},
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Online pill ───────────────────────────────────────────────────────────────

class _OnlinePill extends StatelessWidget {
  final bool online;
  const _OnlinePill({required this.online});

  @override
  Widget build(BuildContext context) {
    final color = online ? AppTheme.success : AppTheme.onSurfaceSub;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 7, height: 7,
              decoration:
              BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 5),
          Text(online ? '● Online' : '● Offline',
              style: TextStyle(
                  color: color, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ── Info card ─────────────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final CameraModel camera;
  const _InfoCard({required this.camera});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _InfoRow(
            icon:  CupertinoIcons.barcode,
            label: 'Serial',
            value: camera.serialNumber,
          ),
          _divider(),
          _InfoRow(
            icon:  CupertinoIcons.info_circle_fill,
            label: 'Firmware',
            value: camera.firmware.isEmpty ? '—' : camera.firmware,
          ),
          _divider(),
          _InfoRow(
            icon:  CupertinoIcons.wifi,
            label: 'Wi-Fi',
            value: camera.wifiSsid.isEmpty ? '—' : camera.wifiSsid,
          ),
        ],
      ),
    );
  }

  Widget _divider() =>
      Divider(color: Colors.white.withOpacity(0.06), height: 1, indent: 52);
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String   label;
  final String   value;
  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    child: Row(
      children: [
        Icon(icon, color: AppTheme.primary, size: 16),
        const SizedBox(width: 14),
        Expanded(
          child: Text(label,
              style: const TextStyle(
                  color: AppTheme.onSurfaceSub, fontSize: 13)),
        ),
        Text(value,
            style: const TextStyle(
              color:      AppTheme.onSurface,
              fontSize:   13,
              fontWeight: FontWeight.w500,
            )),
      ],
    ),
  );
}

// ── Control tile ──────────────────────────────────────────────────────────────

class _ControlTile extends StatelessWidget {
  final IconData  icon;
  final String    label;
  final Color     color;
  final bool      enabled;
  final VoidCallback onTap;

  const _ControlTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = enabled ? color : AppTheme.onSurfaceSub;
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        decoration: BoxDecoration(
          color: effectiveColor.withOpacity(0.10),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: effectiveColor.withOpacity(0.15),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: effectiveColor, size: 30),
            const SizedBox(height: 10),
            Text(label,
                style: TextStyle(
                  color:      effectiveColor,
                  fontSize:   14,
                  fontWeight: FontWeight.w600,
                )),
          ],
        ),
      ),
    );
  }
}