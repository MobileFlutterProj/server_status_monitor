import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_settings.dart';

class SettingsService {
  static const String _notificationsKey = 'notifications_enabled';
  static const String _autoRefreshKey = 'auto_refresh_enabled';
  static const String _refreshIntervalKey = 'refresh_interval';

  Future<AppSettings> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    return AppSettings(
      notificationsEnabled: prefs.getBool(_notificationsKey) ?? true,
      autoRefreshEnabled: prefs.getBool(_autoRefreshKey) ?? true,
      refreshInterval: prefs.getInt(_refreshIntervalKey) ?? 30,
    );
  }

  Future<void> saveSettings(AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.setBool(_notificationsKey, settings.notificationsEnabled);
    await prefs.setBool(_autoRefreshKey, settings.autoRefreshEnabled);
    await prefs.setInt(_refreshIntervalKey, settings.refreshInterval);
  }
}