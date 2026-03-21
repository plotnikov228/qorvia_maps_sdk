import 'package:flutter/material.dart';
import 'package:qorvia_maps_sdk/qorvia_maps_sdk.dart';

import 'app/app.dart';
import 'features/settings/settings_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SDK globally - this automatically fetches the map tile URL
  await QorviaMapsSDK.init(
    apiKey: 'API_KEY_HERE',
    enableLogging: false,
    offlineConfig: OfflineConfig()
  );

  SdkLogger.debugAll();

  // Initialize settings service
  final settingsService = SettingsService();
  await settingsService.init();

  runApp(QorviaMapsExampleApp(settingsService: settingsService));
}
