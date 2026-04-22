// lib/features/skeleton_stream/service/skeleton_stream_service.dart

import 'dart:async';
import 'dart:developer';
import 'dart:typed_data';

import 'package:altum_view/features/skeleton_stream/service/models/skeleton_model.dart';
import 'package:dio/dio.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

import 'package:altum_view/core/networking/dio_client.dart';
import 'package:altum_view/core/constants/api_constants.dart';

const int _jointCount = 18;

class SkeletonStreamService {
  final DioClient _client;
  final int cameraId;
  final String serialNumber;

  SkeletonStreamService({
    required DioClient client,
    required this.cameraId,
    required this.serialNumber,
  }) : _client = client;

  Uint8List? backgroundImage;

  StreamStatus status = StreamStatus.idle;

  String? _groupId;
  String? _streamToken;
  MqttCredentials? _mqttCreds;
  MqttServerClient? _mqtt;

  Timer? _tokenRefreshTimer;
  Timer? _credRefreshTimer;
  Timer? _frameTimeoutTimer;

  bool _running = false;
  bool _reconnecting = false;

  final _frameCtrl =
  StreamController<SkeletonFrame>.broadcast();

  final _statusCtrl =
  StreamController<StreamStatus>.broadcast();

  Stream<SkeletonFrame> get skeletonFrames =>
      _frameCtrl.stream;

  Stream<StreamStatus> get statusStream =>
      _statusCtrl.stream;

  void _setStatus(StreamStatus s) {
    status = s;

    if (!_statusCtrl.isClosed) {
      _statusCtrl.add(s);
    }
  }

  Future<void> start() async {
    if (_running) return;

    _running = true;
    _setStatus(StreamStatus.connecting);

    await _checkCameraStatus();
    await _fetchBackground();

    _groupId ??= await _fetchGroupId();

    if (_mqttCreds == null ||
        _mqttCreds!.isExpired) {
      _mqttCreds =
      await _fetchMqttCredentials();
    }

    _streamToken =
    await _fetchStreamToken();

    await _connectMqtt();

    _tokenRefreshTimer = Timer.periodic(
      const Duration(seconds: 45),
          (_) => _publishToken(),
    );

    _credRefreshTimer = Timer.periodic(
      const Duration(minutes: 5),
          (_) => _checkExpiry(),
    );

    _setStatus(StreamStatus.waitingForFrame);
  }

  Future<void> stop() async {
    _running = false;

    _tokenRefreshTimer?.cancel();
    _credRefreshTimer?.cancel();
    _frameTimeoutTimer?.cancel();

    _tokenRefreshTimer = null;
    _credRefreshTimer = null;
    _frameTimeoutTimer = null;

    if (_mqtt?.connectionStatus?.state ==
        MqttConnectionState.connected) {
      _mqtt!.disconnect();
    }

    _mqtt = null;

    _setStatus(StreamStatus.idle);
  }

  void dispose() {
    _frameCtrl.close();
    _statusCtrl.close();
  }

  Future<void> _checkCameraStatus() async {
    try {
      final resp = await _client.get(
        ApiConstants.cameraById(cameraId),
      );

      final camera =
      resp.data['data']?['camera'];

      if (camera?['is_online'] != true) {
        _setStatus(StreamStatus.offline);
      }
    } catch (_) {}
  }

  Future<void> _fetchBackground() async {
    try {
      final resp = await _client.get(
        ApiConstants.cameraBackground(cameraId),
      );

      final url =
      resp.data['data']?['background_url'];

      if (url == null) return;

      final image =
      await Dio().get<List<int>>(
        url,
        options: Options(
          responseType:
          ResponseType.bytes,
        ),
      );

      if (image.data != null) {
        backgroundImage =
            Uint8List.fromList(
              image.data!,
            );
      }
    } catch (_) {}
  }

  Future<String> _fetchGroupId() async {
    final resp = await _client.get(
      ApiConstants.info,
    );

    return resp.data['data']['group_id']
        .toString();
  }

  Future<MqttCredentials>
  _fetchMqttCredentials() async {
    final resp = await _client.get(
      ApiConstants.mqttAccount,
    );

    return MqttCredentials.fromJson(
      resp.data,
    );
  }

  Future<String> _fetchStreamToken() async {
    final resp = await _client.get(
      ApiConstants.cameraStreamToken(
        cameraId,
      ),
    );

    return resp.data['data']
    ['stream_token']
        .toString();
  }

  Future<void> _connectMqtt() async {
    final creds = _mqttCreds!;

    final port =
    Uri.parse(creds.wssUrl).hasPort
        ? Uri.parse(
      creds.wssUrl,
    ).port
        : 8084;

    _mqtt = MqttServerClient.withPort(
      creds.wssUrl,
      'flutter_${DateTime.now().millisecondsSinceEpoch}',
      port,
    );

    _mqtt!.useWebSocket = true;
    _mqtt!.secure = false;
    _mqtt!.keepAlivePeriod = 30;

    _mqtt!.onDisconnected =
        _onDisconnected;

    _mqtt!.connectionMessage =
        MqttConnectMessage()
            .authenticateAs(
          creds.username,
          creds.password,
        )
            .startClean();

    await _mqtt!.connect();

    _publishToken();

    await Future.delayed(
      const Duration(seconds: 1),
    );

    _mqtt!.subscribe(
      _topic(),
      MqttQos.atMostOnce,
    );

    _mqtt!.updates?.listen(
      _onMessage,
    );
  }

  void _publishToken() {
    if (_mqtt == null ||
        _streamToken == null ||
        _groupId == null) return;

    final topic =
        'mobile/$_groupId/camera/$serialNumber/token/mobileStreamToken';

    final builder =
    MqttClientPayloadBuilder()
      ..addUTF8String(
        _streamToken!,
      );

    _mqtt!.publishMessage(
      topic,
      MqttQos.atLeastOnce,
      builder.payload!,
    );
  }

  void _onDisconnected() {
    if (!_running ||
        _reconnecting) return;

    _reconnecting = true;

    _setStatus(
      StreamStatus.republishing,
    );

    Future.delayed(
      const Duration(seconds: 5),
          () async {
        try {
          _mqtt = null;
          await _connectMqtt();

          _reconnecting = false;

          _setStatus(
            StreamStatus
                .waitingForFrame,
          );
        } catch (_) {
          _reconnecting = false;
        }
      },
    );
  }

  Future<void> _checkExpiry() async {
    if (_mqttCreds == null ||
        !_mqttCreds!.isExpired) {
      return;
    }

    _mqttCreds = null;
    _mqtt?.disconnect();
    _mqtt = null;

    await start();
  }

  void _onMessage(
      List<MqttReceivedMessage<MqttMessage>>
      messages,
      ) {
    for (final msg in messages) {
      final payload =
      msg.payload
      as MqttPublishMessage;

      final bytes = Uint8List.fromList(
        payload.payload.message
            .toList(),
      );

      if (bytes.length < 8) continue;

      final frame =
      _parseFrame(bytes);

      if (!_frameCtrl.isClosed) {
        _frameCtrl.add(frame);
      }

      _setStatus(StreamStatus.live);

      _frameTimeoutTimer?.cancel();

      _frameTimeoutTimer = Timer(
        const Duration(seconds: 3),
            () {
          if (_running) {
            _setStatus(
              StreamStatus
                  .waitingForFrame,
            );
          }
        },
      );
    }
  }

  SkeletonFrame _parseFrame(
      Uint8List bytes,
      ) {
    final persons =
    <List<SkeletonJoint>>[];

    final bd = ByteData.view(
      bytes.buffer,
    );

    final personCount =
    bd.getUint32(
      4,
      Endian.little,
    );

    for (int i = 0;
    i < personCount;
    i++) {
      final start =
          8 + (152 * i);

      final x =
      <double>[];

      final y =
      <double>[];

      for (int j = 0;
      j < 18;
      j++) {
        x.add(
          bd.getFloat32(
            start +
                8 +
                (j * 4),
            Endian.little,
          ),
        );
      }

      for (int j = 0;
      j < 18;
      j++) {
        y.add(
          bd.getFloat32(
            start +
                80 +
                (j * 4),
            Endian.little,
          ),
        );
      }

      final joints =
      <SkeletonJoint>[];

      for (int j = 0;
      j < _jointCount;
      j++) {
        joints.add(
          SkeletonJoint(
            x[j],
            y[j],
          ),
        );
      }

      persons.add(joints);
    }

    return SkeletonFrame(
      persons: persons,
      receivedAt: DateTime.now(),
    );
  }

  String _topic() {
    return 'mobileClient/$_groupId/camera/$serialNumber/skeleton/$_streamToken';
  }
}