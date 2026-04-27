import 'dart:developer';

import 'package:altum_view/core/constants/api_constants.dart';
import 'package:altum_view/core/networking/dio_client.dart';
import 'package:altum_view/core/services/ble_services.dart';
import 'package:altum_view/features/device_connection/models/camera_setup_result_model.dart';
import 'package:altum_view/features/rooms/service/room_model.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class DeviceConnectionService {
  DeviceConnectionService({
    required BleService ble,
    required DioClient  client,
  })  : _ble    = ble,
        _client = client;

  final BleService _ble;
  final DioClient  _client;

  // ── BLE state ──────────────────────────────────────────────────────────────

  String? get deviceSerialNumber => _ble.deviceSerialNumber;
  String? get firmwareVersion    => _ble.firmwareVersion;

  // ── Scan & connect ─────────────────────────────────────────────────────────

  Future<void> startScan(void Function(BluetoothDevice) onDeviceFound) =>
      _ble.startScan(onDeviceFound);

  Future<void> connectToDevice(dynamic device) =>
      _ble.connectToDevice(device);

  Future<Map<String, dynamic>> getDeviceInfo() =>
      _ble.getDeviceInfo();

  // ── Cloud: Bluetooth token ─────────────────────────────────────────────────

  Future<String> getBluetoothToken(String serialNumber) async {
    final resp = await _client.get(ApiConstants.bluetoothToken(serialNumber));
    final data = resp.data as Map<String, dynamic>;

    if (data['success'] != true) {
      throw Exception(data['message'] ?? 'Token request failed');
    }

    final payload      = data['data'] as Map<String, dynamic>;
    final cameraExists = payload['camera_exist'] == true;

    if (cameraExists) {
      log('⚠️  Camera already exists — deleting before fresh registration');
      await _deleteCamera(serialNumber);

      final freshResp = await _client.get(ApiConstants.bluetoothToken(serialNumber));
      final freshData = freshResp.data as Map<String, dynamic>;
      if (freshData['success'] != true) {
        throw Exception(freshData['message'] ?? 'Fresh token request failed');
      }
      final freshToken = freshData['data']['bluetooth_token'];
      if (freshToken == null) throw Exception('bluetooth_token missing in fresh response');
      return freshToken.toString();
    }

    final token = payload['bluetooth_token'];
    if (token == null) throw Exception('bluetooth_token missing in response');
    return token.toString();
  }

  // ── Cloud: rooms ───────────────────────────────────────────────────────────

  Future<List<RoomModel>> getRooms() async {
    final resp = await _client.get(ApiConstants.rooms);
    final arr  = resp.data['data']?['rooms']?['array'] as List? ?? [];
    return arr.cast<Map<String, dynamic>>().map(RoomModel.fromJson).toList();
  }

  // ── Cloud: register camera ─────────────────────────────────────────────────

  Future<CameraSetupResultModel> createCamera({
    required String serial,
    required String firmwareVersion,
    required int    roomId,
  }) async {
    final resp = await _client.post(
      ApiConstants.cameras,
      data: {
        'friendly_name':     serial.length > 20 ? serial.substring(0, 20) : serial,
        'room_id':           roomId,
        'serial_number':     serial,
        'version':           firmwareVersion,
        'is_initial_config': true,
      },
    );

    final json = resp.data as Map<String, dynamic>;
    if (json['success'] != true) {
      throw Exception(json['message'] ?? 'Unknown API error');
    }

    final camera = json['data']?['camera'] as Map<String, dynamic>?;
    if (camera == null) throw Exception('Invalid camera response format');

    final mqttPasscode = camera['mqtt_passcode'];
    if (mqttPasscode == null || mqttPasscode.toString().isEmpty) {
      throw Exception('mqtt_passcode missing or empty');
    }

    log('📸 Camera ID: ${camera['id']}  MQTT pass: $mqttPasscode');
    return CameraSetupResultModel(
      cameraId:     (camera['id'] as num).toInt(),
      mqttPasscode: mqttPasscode.toString(),
    );
  }

  // ── BLE: WiFi provisioning ─────────────────────────────────────────────────

  Future<List<String>> getWifiList() async {
    _ble.deviceWifiList.clear();
    await _ble.getWifiList();
    return List.from(_ble.deviceWifiList);
  }

  Future<Map<String, dynamic>> disconnectFromPreviousNetwork(String token) =>
      _ble.disconnectFromPreviousNetwork(token);

  Future<Map<String, dynamic>> setServer(String token) =>
      _ble.setServer(token);

  Future<Map<String, dynamic>> setWifi({
    required String token,
    required String ssid,
    required String password,
    required String mqttPasscode,
    required String groupId,
  }) =>
      _ble.setWifi(
        token:        token,
        ssid:         ssid,
        password:     password,
        mqttPasscode: mqttPasscode,
        groupId:      groupId,
      );

  // ── Private helpers ────────────────────────────────────────────────────────

  Future<void> _deleteCamera(String serialNumber) async {
    final listResp = await _client.get(ApiConstants.camerasBy(serialNumber));
    final cameras  = listResp.data['data']?['cameras'];
    int?  cameraId;

    if (cameras is Map) {
      final arr = cameras['array'];
      if (arr is List && arr.isNotEmpty) {
        cameraId = (arr[0] as Map)['id'];
      }
    }

    if (cameraId == null) {
      log('⚠️  No existing camera to delete, continuing...');
      return;
    }

    await _client.delete(ApiConstants.cameraById(cameraId));
    log('🗑️  Camera $cameraId deleted');
  }


  Future<void> disconnect() async {
    await _ble.disconnect();
  }
}