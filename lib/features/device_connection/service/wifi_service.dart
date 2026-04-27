import 'package:altum_view/core/services/ble_services.dart';

class WifiService {
  WifiService(this._ble);

  final BleService _ble;

  // ── Networks ───────────────────────────────────────────────────────────────

  Future<List<String>> getAvailableNetworks() async {
    _ble.deviceWifiList.clear();
    await _ble.getWifiList();
    return List.from(_ble.deviceWifiList);
  }

  // ── BLE commands ───────────────────────────────────────────────────────────

  Future<void> disconnect(String token) =>
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
}