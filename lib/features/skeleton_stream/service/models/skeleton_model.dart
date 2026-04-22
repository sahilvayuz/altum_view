// lib/features/skeleton_stream/service/skeleton_model.dart

class SkeletonJoint {
  final double x;
  final double y;

  const SkeletonJoint(this.x, this.y);
}

class SkeletonFrame {
  final List<List<SkeletonJoint>> persons;
  final DateTime receivedAt;

  const SkeletonFrame({
    required this.persons,
    required this.receivedAt,
  });

  bool get isEmpty => persons.isEmpty;
}

class MqttCredentials {
  final String username;
  final String password;
  final String wssUrl;
  final DateTime expiresAt;

  const MqttCredentials({
    required this.username,
    required this.password,
    required this.wssUrl,
    required this.expiresAt,
  });

  bool get isExpired =>
      DateTime.now().isAfter(
        expiresAt.subtract(
          const Duration(minutes: 2),
        ),
      );

  factory MqttCredentials.fromJson(
      Map<String, dynamic> json,
      ) {
    final data =
        json['data']
        as Map<String, dynamic>? ??
            {};

    final account =
        data['mqtt_account']
        as Map<String, dynamic>? ??
            data;

    DateTime parseExpiry(dynamic v) {
      if (v is int) {
        return DateTime
            .fromMillisecondsSinceEpoch(
          v * 1000,
        );
      }

      if (v is String) {
        return DateTime.tryParse(v) ??
            DateTime.now().add(
              const Duration(hours: 1),
            );
      }

      return DateTime.now().add(
        const Duration(hours: 1),
      );
    }

    return MqttCredentials(
      username:
      account['username']
          ?.toString() ??
          '',

      password:
      account['passcode']
          ?.toString() ??
          account['password']
              ?.toString() ??
          '',

      wssUrl:
      data['wss_url']
          ?.toString() ??
          account['wss_url']
              ?.toString() ??
          '',

      expiresAt: parseExpiry(
        account['expires_at'],
      ),
    );
  }
}

enum StreamStatus {
  idle,
  connecting,
  live,
  waitingForFrame,
  republishing,
  offline,
  error,
}