class SDKConfig {
  static bool isSdkMode = false;

  static String? clientId;
  static String? clientSecret;
  static String? scope;

  static void enableSDK({
    required String id,
    required String secret,
    required String sdkScope,
  }) {
    isSdkMode = true;
    clientId = id;
    clientSecret = secret;
    scope = sdkScope;
  }

  static void disableSDK() {
    isSdkMode = false;
    clientId = null;
    clientSecret = null;
    scope = null;
  }
}