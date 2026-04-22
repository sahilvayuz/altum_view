// lib/features/camera/service/models/camera_model.dart

class CameraModel {
  final int id;

  final String serialNumber;
  final String friendlyName;

  final bool isOnline;
  final bool isStreaming;
  final bool isCalibrated;
  final bool useBetaFirmware;
  final bool isCurrentBeta;
  final bool isUpdateAvailable;

  final int status;
  final int deviceType;
  final int updatingStatus;
  final int backgroundType;

  final int? roomId;
  final String roomName;

  final int wifiStrength;
  final String wifiSsid;

  final String model;
  final String firmware;

  const CameraModel({
    required this.id,
    required this.serialNumber,
    required this.friendlyName,
    required this.isOnline,
    required this.isStreaming,
    required this.isCalibrated,
    required this.useBetaFirmware,
    required this.isCurrentBeta,
    required this.isUpdateAvailable,
    required this.status,
    required this.deviceType,
    required this.updatingStatus,
    required this.backgroundType,
    required this.roomId,
    required this.roomName,
    required this.wifiStrength,
    required this.wifiSsid,
    required this.model,
    required this.firmware,
  });

  factory CameraModel.fromJson(Map<String, dynamic> j) {
    return CameraModel(
      id: _toInt(j['id']),

      serialNumber: _toStr(j['serial_number']),
      friendlyName: _toStr(
        j['friendly_name'],
        fallback: _toStr(j['serial_number']),
      ),

      isOnline: _toBool(j['is_online']),
      isStreaming: _toBool(j['is_streaming']),
      isCalibrated: _toBool(j['is_calibrated']),
      useBetaFirmware: _toBool(j['use_beta_firmware']),
      isCurrentBeta: _toBool(j['is_current_beta']),
      isUpdateAvailable: _toBool(j['is_update_available']),

      status: _toInt(j['status']),
      deviceType: _toInt(j['device_type']),
      updatingStatus: _toInt(j['updating_status']),
      backgroundType: _toInt(j['background_type']),

      roomId: j['room_id'] == null ? null : _toInt(j['room_id']),
      roomName: _toStr(j['room_name']),

      wifiStrength: _toInt(j['wifi_strength']),
      wifiSsid: _toStr(j['wifi_ssid']),

      model: _toStr(j['model']),
      firmware: _toStr(j['version']),
    );
  }

  CameraModel copyWith({
    int? id,
    String? serialNumber,
    String? friendlyName,
    bool? isOnline,
    bool? isStreaming,
    bool? isCalibrated,
    bool? useBetaFirmware,
    bool? isCurrentBeta,
    bool? isUpdateAvailable,
    int? status,
    int? deviceType,
    int? updatingStatus,
    int? backgroundType,
    int? roomId,
    String? roomName,
    int? wifiStrength,
    String? wifiSsid,
    String? model,
    String? firmware,
  }) {
    return CameraModel(
      id: id ?? this.id,
      serialNumber: serialNumber ?? this.serialNumber,
      friendlyName: friendlyName ?? this.friendlyName,
      isOnline: isOnline ?? this.isOnline,
      isStreaming: isStreaming ?? this.isStreaming,
      isCalibrated: isCalibrated ?? this.isCalibrated,
      useBetaFirmware: useBetaFirmware ?? this.useBetaFirmware,
      isCurrentBeta: isCurrentBeta ?? this.isCurrentBeta,
      isUpdateAvailable:
      isUpdateAvailable ?? this.isUpdateAvailable,
      status: status ?? this.status,
      deviceType: deviceType ?? this.deviceType,
      updatingStatus: updatingStatus ?? this.updatingStatus,
      backgroundType: backgroundType ?? this.backgroundType,
      roomId: roomId ?? this.roomId,
      roomName: roomName ?? this.roomName,
      wifiStrength: wifiStrength ?? this.wifiStrength,
      wifiSsid: wifiSsid ?? this.wifiSsid,
      model: model ?? this.model,
      firmware: firmware ?? this.firmware,
    );
  }
}

/// ---------------------------------------------------------------------------
/// Safe Parsers
/// ---------------------------------------------------------------------------

int _toInt(dynamic value) {
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

bool _toBool(dynamic value) {
  if (value is bool) return value;
  if (value is int) return value == 1;
  if (value is String) {
    return value == 'true' || value == '1';
  }
  return false;
}

String _toStr(dynamic value, {String fallback = ''}) {
  if (value == null) return fallback;
  return value.toString();
}