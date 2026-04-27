// ============================================================
// device_connection_controller.dart
// ============================================================

import 'dart:developer';

import 'package:altum_view/features/device_connection/service/device_connection_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

enum SetupStep {
  scan,
  connecting,
  wifi,
  progress,
  success,
  error,
}

class DeviceConnectionController extends ChangeNotifier {
  DeviceConnectionController(this._service);

  final DeviceConnectionService _service;

  bool _disposed = false;

  // ── State ───────────────────────────────────────────────
  SetupStep step = SetupStep.scan;
  String statusMessage = '';
  List<String> wifiList = [];

  BluetoothDevice? _device;
  String? _token;
  String? _mqttPasscode;
  int? _roomId;

  // ── Scan ────────────────────────────────────────────────
  Future<void> startScan() async {
    _setStep(SetupStep.scan, 'Scanning for devices…');

    try {
      await _service.startScan(_onDeviceFound);
    } catch (e) {
      _fail(e.toString());
    }
  }

  // ── Device Found ────────────────────────────────────────
  void _onDeviceFound(BluetoothDevice device) async {
    _device = device;

    _setStep(SetupStep.connecting, 'Connecting to device…');

    try {
      await _service.connectToDevice(device);

      _setStep(SetupStep.connecting, 'Reading device info…');
      await _service.getDeviceInfo();

      final serial = _service.deviceSerialNumber;
      if (serial == null) {
        throw Exception('Serial number missing');
      }

      _setStep(SetupStep.connecting, 'Getting token…');
      _token = await _service.getBluetoothToken(serial);

      _setStep(SetupStep.connecting, 'Scanning Wi-Fi…');
      wifiList = await _service.getWifiList();

      _setStep(SetupStep.wifi, '');
    } catch (e) {
      _fail(e.toString());
    }
  }

  // ── Wi-Fi Submit ────────────────────────────────────────
  Future<void> submitWifi(String ssid, String password) async {
    try {
      _setStep(SetupStep.progress, 'Connecting to Wi-Fi…');

      if (_token == null) throw Exception('Bluetooth token missing');

      final serial = _service.deviceSerialNumber;
      if (serial == null) throw Exception('Serial missing');

      _setStep(SetupStep.progress, 'Disconnecting old network…');
      await _service.disconnectFromPreviousNetwork(_token!);

      _setStep(SetupStep.progress, 'Setting server…');
      await _service.setServer(_token!);

      _setStep(SetupStep.progress, 'Getting rooms…');
      final rooms = await _service.getRooms();

      _roomId = rooms.first.id;

      final cam = await _service.createCamera(
        serial: serial,
        firmwareVersion: _service.firmwareVersion ?? '',
        roomId: _roomId!,
      );

      _mqttPasscode = cam.mqttPasscode;

      _setStep(SetupStep.progress, 'Sending credentials…');

      final result = await _service.setWifi(
        token: _token!,
        ssid: ssid,
        password: password,
        mqttPasscode: _mqttPasscode!,
        groupId: '4528',
      );

      if (result['wifi_status'] == 'success') {
        _setStep(SetupStep.success, '');
      } else {
        throw Exception('Wi-Fi failed');
      }
    } catch (e) {
      _fail(e.toString());
    }
  }

  // ── Dispose Controller ──────────────────────────────────
  Future<void> disposeController() async {
    try {
      await _service.disconnect();
    } catch (_) {}

    reset();
  }

  // ── Reset ───────────────────────────────────────────────
  void reset() {
    step = SetupStep.scan;
    statusMessage = '';
    wifiList.clear();

    _device = null;
    _token = null;
    _mqttPasscode = null;
    _roomId = null;

    _safeNotify();
  }

  // ── Helpers ─────────────────────────────────────────────
  void _setStep(SetupStep s, String msg) {
    step = s;
    statusMessage = msg;
    _safeNotify();
  }

  void _fail(String msg) {
    log(msg);

    step = SetupStep.error;
    statusMessage = msg;

    _safeNotify();
  }

  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}