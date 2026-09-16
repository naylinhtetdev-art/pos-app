import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class DeviceService {
  static const String _installationIdKey = 'installation_id';

  final Uuid _uuid = Uuid();

  Future<String> getInstallationId() async {
    final prefs = await SharedPreferences.getInstance();

    String? installationId = prefs.getString(_installationIdKey);

    if (installationId == null || installationId.isEmpty) {
      installationId = _uuid.v4();

      await prefs.setString(_installationIdKey, installationId);
    }

    return installationId;
  }
}
