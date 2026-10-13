import 'package:kazumi/services/storage/storage.dart';

Map<String, String> get dandanCredentials =>
    const bool.fromEnvironment('KAZUMI_TV')
    ? {
        'id': GStorage.getSetting(SettingsKeys.dandanAppId),
        'value': GStorage.getSetting(SettingsKeys.dandanAppSecret),
      }
    : const {
        'id': String.fromEnvironment('DANDANAPI_APPID'),
        'value': String.fromEnvironment('DANDANAPI_KEY'),
      };
