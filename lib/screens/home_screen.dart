import 'dart:async'; // Добавляем для Timer
import 'package:flutter/material.dart';
import '../services/server_monitor_service.dart';
import '../services/settings_service.dart';
import '../models/app_settings.dart';
import '../models/server_stats.dart'; // Добавляем импорт
import '../widgets/stats_card.dart';
import '../widgets/add_server_dialog.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ServerMonitorService _monitorService = ServerMonitorService();
  final SettingsService _settingsService = SettingsService();
  final List<ServerStats> _serverStats = [];
  Timer? _refreshTimer;
  late AppSettings _settings;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _addSampleServer();
  }

  void _loadSettings() async {
    _settings = await _settingsService.loadSettings();
    _startAutoRefresh();
  }

  void _startAutoRefresh() {
    _refreshTimer?.cancel();
    
    if (_settings.autoRefreshEnabled) {
      _refreshTimer = Timer.periodic(
        Duration(minutes: _settings.refreshInterval),
        (timer) => _refreshAllServers(),
      );
    }
  }

  void _addSampleServer() {
    _monitorService.addServer(ServerConfig(
      name: 'Main Server',
      host: '192.168.1.100',
      username: 'username',
      password: 'password',
    ));
    _refreshAllServers();
  }

  Future<void> _refreshAllServers() async {
    try {
      final futures = _monitorService.servers.map((server) {
        return _monitorService.getServerStats(server);
      }).toList();

      final results = await Future.wait(futures);
      
      if (mounted) {
        setState(() {
          _serverStats.clear();
          _serverStats.addAll(results);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка обновления: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _addServer() {
    showDialog(
      context: context,
      builder: (context) => AddServerDialog(
        onAdd: (config) {
          _monitorService.addServer(config);
          _refreshAllServers();
        },
      ),
    );
  }

  void _openSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SettingsScreen(
          initialSettings: _settings,
          onSettingsSaved: (newSettings) {
            setState(() {
              _settings = newSettings;
            });
            _startAutoRefresh();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Server Status Monitor',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _openSettings,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshAllServers,
          ),
        ],
      ),
      body: _serverStats.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.computer, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Нет добавленных серверов\nНажмите "+" чтобы добавить',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _refreshAllServers,
              child: ListView.builder(
                itemCount: _serverStats.length,
                itemBuilder: (context, index) {
                  return StatsCard(stats: _serverStats[index]);
                },
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addServer,
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}