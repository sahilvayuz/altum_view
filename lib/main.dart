import 'package:flutter/material.dart';
import 'altum_view_sdk.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await AltumViewSDK.initialize(
    embeddedMode: false,
  );
}