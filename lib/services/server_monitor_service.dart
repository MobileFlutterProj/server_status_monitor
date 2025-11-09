import '../models/server_stats.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'native_ssh_client.dart';
import 'dart:convert';

class ServerMonitorService {
  final List<ServerConfig> _servers = [];
  final Map<String, ServerStats> _cache = {};

  List<ServerConfig> get servers => List.unmodifiable(_servers);

  static const String _serversKey = 'saved_servers';

  // Загрузить серверы при старте
  Future<void> loadServers() async {
    final prefs = await SharedPreferences.getInstance();
    final serversJson = prefs.getStringList(_serversKey) ?? [];
    _servers.clear();
    for (final jsonStr in serversJson) {
      final map = json.decode(jsonStr) as Map<String, dynamic>;
      _servers.add(ServerConfig.fromMap(map));
    }
  }

  // Сохранить серверы при изменении
  Future<void> _saveServers() async {
    final prefs = await SharedPreferences.getInstance();
    final serversJson = _servers.map((server) {
      return json.encode(server.toMap());
    }).toList();
    await prefs.setStringList(_serversKey, serversJson);
  }

  void addServer(ServerConfig config) {
    _servers.add(config);
    _saveServers(); // сохраняем сразу
  }

  void updateServer(ServerConfig updatedConfig) {
    final index = _servers.indexWhere((server) => server.id == updatedConfig.id);
    if (index != -1) {
      _servers[index] = updatedConfig;
      _saveServers();
    }
  }

  void removeServer(String id) {
    _servers.removeWhere((server) => server.id == id);
    _cache.remove(id);
    _saveServers();
  }

  ServerConfig? getServerById(String id) {
    try {
      return _servers.firstWhere((server) => server.id == id);
    } catch (e) {
      return null;
    }
  }

  void _saveToCache(ServerConfig config, ServerStats stats) {
    _cache[config.id] = stats;
  }

  ServerStats? _getFromCache(ServerConfig config) {
    final cached = _cache[config.id];
    if (cached != null && cached.isCacheValid) {
      return cached.asCached();
    }
    return null;
  }

  Future<ServerStats> getServerStats(ServerConfig config) async {
    try {
      // Выполняем команды через нативный клиент
      final cpuOutput = await NativeSSHClient.execute(
        host: config.host,
        port: config.port,
        username: config.username,
        password: config.password,
        command: 'top -bn1 | grep "Cpu(s)"',
      );
      final memoryOutput = await NativeSSHClient.execute(
        host: config.host,
        port: config.port,
        username: config.username,
        password: config.password,
        command: 'free | grep Mem:',
      );
      final diskOutput = await NativeSSHClient.execute(
        host: config.host,
        port: config.port,
        username: config.username,
        password: config.password,
        command: 'df / | tail -1',
      );
      final uptimeOutput = await NativeSSHClient.execute(
        host: config.host,
        port: config.port,
        username: config.username,
        password: config.password,
        command: 'cat /proc/uptime',
      );
      final tempOutput = await NativeSSHClient.execute(
        host: config.host,
        port: config.port,
        username: config.username,
        password: config.password,
        command:
            'cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null || cat /sys/class/thermal/thermal_zone1/temp 2>/dev/null || echo "0"',
      );
      final networkOutput = await NativeSSHClient.execute(
        host: config.host,
        port: config.port,
        username: config.username,
        password: config.password,
        command:
            'cat /proc/net/dev | grep -E "(eth0|ens|wlan|wlo1)" | head -1',
      );
      final hostnameOutput = await NativeSSHClient.execute(
        host: config.host,
        port: config.port,
        username: config.username,
        password: config.password,
        command: 'hostname',
      );

      final currentStats = ServerStats(
        serverName: config.name,
        ipAddress: config.host,
        lastUpdate: DateTime.now(),
        cpuUsage: _parseCpuUsage(cpuOutput),
        memoryUsage: _parseMemoryUsage(memoryOutput),
        diskUsage: _parseDiskUsage(diskOutput),
        networkUsage: _parseNetworkUsage(networkOutput),
        temperature: _parseTemperature(tempOutput),
        uptime: _parseUptime(uptimeOutput),
        isOnline: true,
      );

      _saveToCache(config, currentStats);
      return currentStats;

    } catch (e) {
      print('SSH Error for ${config.name}: $e');
      final cached = _getFromCache(config);
      if (cached != null) return cached;

      return ServerStats(
        serverName: config.name,
        ipAddress: config.host,
        lastUpdate: DateTime.now(),
        cpuUsage: 0,
        memoryUsage: 0,
        diskUsage: 0,
        networkUsage: 0,
        temperature: 0,
        uptime: 0,
        isOnline: false,
      );
    }
  }

  double _parseCpuUsage(String? cpuOutput) {
  try {
    if (cpuOutput == null || cpuOutput.isEmpty) return 0;

    // Поддержка как точки, так и запятой как десятичного разделителя
    final match = RegExp(r'([\d,\.]+)\s+id').firstMatch(cpuOutput);
    if (match != null) {
      // Заменяем запятую на точку перед парсингом
      final idleStr = match.group(1)!.replaceAll(',', '.');
      final idle = double.tryParse(idleStr) ?? 0.0;
      return (100 - idle).clamp(0, 100);
    }
  } catch (e) {
    print('Error parsing CPU: $e');
  }
  return 0;
}

  double _parseMemoryUsage(String? memoryOutput) {
    try {
      if (memoryOutput == null || memoryOutput.isEmpty) return 0;
      final parts = memoryOutput.trim().split(RegExp(r'\s+'));
      if (parts.length >= 3) {
        final total = double.parse(parts[1]);
        final used = double.parse(parts[2]);
        if (total > 0) {
          return ((used / total) * 100).clamp(0, 100);
        }
      }
    } catch (e) {
      print('Error parsing memory: $e');
    }
    return 0;
  }

  double _parseDiskUsage(String? diskOutput) {
    try {
      if (diskOutput == null || diskOutput.isEmpty) return 0;
      final parts = diskOutput.trim().split(RegExp(r'\s+'));
      if (parts.length >= 5) {
        final usage = parts[4].replaceAll('%', '');
        return double.parse(usage).clamp(0, 100);
      }
    } catch (e) {
      print('Error parsing disk: $e');
    }
    return 0;
  }

  int _parseUptime(String? uptimeOutput) {
    try {
      if (uptimeOutput == null || uptimeOutput.isEmpty) return 0;
      final parts = uptimeOutput.split(' ');
      if (parts.isNotEmpty) {
        return double.parse(parts[0]).round();
      }
    } catch (e) {
      print('Error parsing uptime: $e');
    }
    return 0;
  }

  double _parseTemperature(String? tempOutput) {
    try {
      if (tempOutput == null || tempOutput.isEmpty) return 0;
      final temp = int.tryParse(tempOutput.trim());
      if (temp != null && temp > 0) {
        return temp / 1000.0;
      }
    } catch (e) {
      print('Error parsing temperature: $e');
    }
    return 0;
  }

  double _parseNetworkUsage(String? networkOutput) {
  try {
    if (networkOutput == null || networkOutput.isEmpty) return 0;
    final parts = networkOutput.split(':');
    if (parts.length >= 2) {
      final values = parts[1].trim().split(RegExp(r'\s+'));
      if (values.length >= 2) {
        final receivedBytes = double.tryParse(values[0]) ?? 0;
        return (receivedBytes / (1024 * 1024)).clamp(0, double.infinity);
      }
    }
  } catch (e) {
    print('Error parsing network: $e');
  }
  return 0;
}
}

class ServerConfig {
  final String id;
  final String name;
  final String host;
  final int port;
  final String username;
  final String password;
  final String category;
  final String description;
  final String authType;

  ServerConfig({
    String? id,
    required this.name,
    required this.host,
    this.port = 22,
    required this.username,
    required this.password,
    this.category = 'production',
    this.description = '',
    this.authType = 'password',
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'host': host,
      'port': port,
      'username': username,
      'password': password,
      'category': category,
      'description': description,
      'authType': authType,
    };
  }

  factory ServerConfig.fromMap(Map<String, dynamic> map) {
  return ServerConfig(
    id: map['id'],
    name: map['name'],
    host: map['host'],
    port: map['port'],
    username: map['username'],
    password: map['password'],
    category: map['category'] ?? 'production',
    description: map['description'] ?? '',
    authType: map['authType'] ?? 'password',
  );
}
}