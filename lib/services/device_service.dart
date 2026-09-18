import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class DeviceService {
  static const String _installationIdKey = 'installation_id';

  final Uuid _uuid = Uuid();
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  Future<String> getInstallationId() async {
    final prefs = await SharedPreferences.getInstance();

    String? installationId = prefs.getString(_installationIdKey);

    if (installationId == null || installationId.isEmpty) {
      installationId = _uuid.v4();

      await prefs.setString(_installationIdKey, installationId);
    }

    return installationId;
  }

  // ==========================================
  // Device Name
  // ==========================================

  Future<String> getDeviceName() async {
    try {
      // Android
      if (Platform.isAndroid) {
        final info = await _deviceInfo.androidInfo;

        return '${info.manufacturer} ${info.model}';
      }

      // iPhone / iPad
      if (Platform.isIOS) {
        final info = await _deviceInfo.iosInfo;

        return info.name;
      }

      return 'Unknown Device';
    } catch (e) {
      return 'Unknown Device';
    }
  }
}
