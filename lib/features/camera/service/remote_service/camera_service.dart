// lib/features/camera/service/remote_service/camera_service.dart

import 'package:altum_view/core/constants/api_constants.dart';
import 'package:altum_view/core/networking/dio_client.dart';
import 'package:altum_view/features/camera/service/models/camera_model.dart';

class CameraService {
  final DioClient _client;

  const CameraService(this._client);

  /// -------------------------------------------------------------------------
  /// GET /cameras?room_id=X
  ///
  /// Used for room camera listing
  /// -------------------------------------------------------------------------
  Future<List<CameraModel>> getCamerasForRoom(int roomId) async {
    final resp = await _client.get<Map<String, dynamic>>(
      ApiConstants.cameras,
      query: {
        'room_id': roomId,
      },
    );

    final root = resp.data ?? {};

    final data =
        root['data'] as Map<String, dynamic>? ?? {};

    final cameras =
        data['cameras'] as Map<String, dynamic>? ?? {};

    final list =
        cameras['array'] as List<dynamic>? ?? [];

    return list
        .whereType<Map<String, dynamic>>()
        .map((json) => CameraModel.fromJson(
      _normalizeCameraJson(json),
    ))
        .toList();
  }

  /// -------------------------------------------------------------------------
  /// GET /cameras/:id
  ///
  /// Used for detail screen
  /// -------------------------------------------------------------------------
  Future<CameraModel> getCameraById(int id) async {
    final resp = await _client.get<Map<String, dynamic>>(
      ApiConstants.cameraById(id),
    );

    final root = resp.data ?? {};

    final data =
        root['data'] as Map<String, dynamic>? ?? {};

    final camera =
    data['camera'] as Map<String, dynamic>?;

    if (camera == null) {
      throw Exception('camera missing from response');
    }

    return CameraModel.fromJson(
      _normalizeCameraJson(camera),
    );
  }

  /// -------------------------------------------------------------------------
  /// API NORMALIZER
  ///
  /// Your list API gives:
  /// wifi_strength
  /// version
  ///
  /// But UI expects:
  /// wifi_ssid
  /// firmware
  ///
  /// So we normalize here.
  /// -------------------------------------------------------------------------
  Map<String, dynamic> _normalizeCameraJson(Map<String, dynamic> json,) {
    final map = Map<String, dynamic>.from(json);

    /// If wifi_ssid missing, show strength instead
    if (map['wifi_ssid'] == null ||
        map['wifi_ssid'].toString().isEmpty) {
      final strength = map['wifi_strength'];

      if (strength != null) {
        map['wifi_ssid'] = '$strength dBm';
      } else {
        map['wifi_ssid'] = 'Unknown';
      }
    }

    /// API uses version -> firmware
    if (map['firmware'] == null ||
        map['firmware'].toString().isEmpty) {
      map['firmware'] = map['version'] ?? '';
    }

    /// fallback friendly name
    if (map['friendly_name'] == null ||
        map['friendly_name'].toString().isEmpty) {
      map['friendly_name'] =
          map['serial_number'] ?? 'Camera';
    }

    return map;
  }
}