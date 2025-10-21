import 'package:flutter/material.dart';
import 'dart:async';
import '../services/server_monitor_service.dart';
import '../services/settings_service.dart';
import '../models/app_settings.dart';
import '../models/server_stats.dart';
import '../widgets/stats_card.dart';
import 'edit_server_screen.dart';
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

  void _showServerMenu(BuildContext context, int index) {
    final serverConfig = _monitorService.servers[index];
    
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Редактировать'),
            onTap: () {
              Navigator.pop(context);
              _editServer(serverConfig);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('Удалить', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              _deleteServer(serverConfig.id, index);
            },
          ),
          ListTile(
            leading: const Icon(Icons.refresh),
            title: const Text('Обновить сейчас'),
            onTap: () {
              Navigator.pop(context);
              _refreshServer(index);
            },
          ),
        ],
      ),
    );
  }

  void _editServer(ServerConfig server) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditServerScreen(
          server: server,
          onSave: (updatedConfig) {
            _monitorService.updateServer(updatedConfig);
            _refreshAllServers();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Сервер обновлен')),
            );
          },
        ),
      ),
    );
  }

  void _deleteServer(String serverId, int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить сервер?'),
        content: Text('Вы уверены, что хотите удалить сервер "${_serverStats[index].serverName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              _monitorService.removeServer(serverId);
              setState(() {
                _serverStats.removeAt(index);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Сервер удален')),
              );
            },
            child: const Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _refreshServer(int index) async {
    final serverConfig = _monitorService.servers[index];
    final newStats = await _monitorService.getServerStats(serverConfig);
    
    setState(() {
      _serverStats[index] = newStats;
    });
  }

  void _addServer() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditServerScreen(
          onSave: (config) {
            _monitorService.addServer(config);
            _refreshAllServers();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Сервер добавлен')),
            );
          },
        ),
      ),
    );
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
                  return GestureDetector(
                    onLongPress: () => _showServerMenu(context, index),
                    child: StatsCard(stats: _serverStats[index]),
                  );
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