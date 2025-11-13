import 'package:flutter/material.dart';
import '../models/app_settings.dart';
import '../services/settings_service.dart';

class SettingsScreen extends StatefulWidget {
  final AppSettings initialSettings;
  final Function(AppSettings) onSettingsSaved;

  const SettingsScreen({
    super.key,
    required this.initialSettings,
    required this.onSettingsSaved,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late AppSettings _currentSettings;
  final SettingsService _settingsService = SettingsService();

  @override
  void initState() {
    super.initState();
    _currentSettings = widget.initialSettings;
  }

  void _saveSettings() async {
    await _settingsService.saveSettings(_currentSettings);
    widget.onSettingsSaved(_currentSettings);
    
    // Показываем подтверждение
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Настройки сохранены')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Настройки'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Уведомления
            _buildSettingSwitch(
              title: 'Уведомления',
              subtitle: 'Получать уведомления о проблемах с серверами',
              value: _currentSettings.notificationsEnabled,
              onChanged: (value) {
                setState(() {
                  _currentSettings = _currentSettings.copyWith(
                    notificationsEnabled: value,
                  );
                });
              },
            ),
            
            const SizedBox(height: 16),
            
            // Автообновление
            _buildSettingSwitch(
              title: 'Обновление данных',
              subtitle: 'Автоматически обновлять данные о серверах',
              value: _currentSettings.autoRefreshEnabled,
              onChanged: (value) {
                setState(() {
                  _currentSettings = _currentSettings.copyWith(
                    autoRefreshEnabled: value,
                  );
                });
              },
            ),
            
            const SizedBox(height: 16),
            
            // Частота обновления
            _buildIntervalSetting(),
            
            const Spacer(),
            
            // Кнопка сохранения
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveSettings,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Сохранить',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingSwitch({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Text(
              value ? 'ВКЛ' : 'ВЫКЛ',
              style: TextStyle(
                fontSize: 14,
                color: value ? Colors.green : Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Switch(
              value: value,
              onChanged: onChanged,
              activeColor: Colors.blue,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIntervalSetting() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Частота обновления',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Интервал автоматического обновления данных',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            DropdownButton<int>(
              value: _currentSettings.refreshInterval,
              isExpanded: true,
              items: const [
                DropdownMenuItem(value: 1, child: Text('1 минут')),
                DropdownMenuItem(value: 5, child: Text('5 минут')),
                DropdownMenuItem(value: 10, child: Text('10 минут')),
                DropdownMenuItem(value: 15, child: Text('15 минут')),
                DropdownMenuItem(value: 30, child: Text('30 минут')),
                DropdownMenuItem(value: 60, child: Text('1 час')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _currentSettings = _currentSettings.copyWith(
                      refreshInterval: value,
                    );
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}