import 'package:flutter/material.dart';
import 'package:qorvia_maps_sdk/qorvia_maps_sdk.dart';

import 'app/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SDK globally - this automatically fetches the map tile URL
  await QorviaMapsSDK.init(
    apiKey: 'API KEY HERE',
    enableLogging: true,
  );

  SdkLogger.debugAll();

  runApp(const QorviaMapsExampleApp());
}
