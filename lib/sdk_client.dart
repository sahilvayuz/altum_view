import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import 'package:altum_view/core/networking/dio_client.dart';
import 'package:altum_view/altum_view_sdk.dart';

class SDKClient {
  SDKClient._();

  static DioClient of(BuildContext context) {
    if (AltumViewSDK.isEmbedded) {
      return AltumViewSDK.client;
    }

    return context.read<DioClient>();
  }
}