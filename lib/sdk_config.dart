class SDKConfig {
  static bool isSdkMode = false;

  static void enableSDK() {
    isSdkMode = true;
  }

  static void disableSDK() {
    isSdkMode = false;
  }
}