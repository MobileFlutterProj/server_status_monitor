import 'dart:convert';
import 'package:ssh2/ssh2.dart';
import '../models/server_stats.dart';

class ServerMonitorService {
  final List<ServerConfig> _servers = [];

  List<ServerConfig> get servers => List.unmodifiable(_servers);

  void addServer(ServerConfig config) {
    _servers.add(config);
  }

  void removeServer(String id) {
    _servers.removeWhere((server) => server.id == id);
  }

  Future<ServerStats> getServerStats(ServerConfig config) async {
    try {
      // Создаем SSH соединение
      final client = SSHClient(
        host: config.host,
        port: config.port,
        username: config.username,
        passwordOrKey: config.password,
      );

      // Подключаемся к серверу
      final connectionResult = await client.connect();
      if (connectionResult != true) {
        throw Exception('Failed to connect to server');
      }
      
      // Получаем данные CPU
      final cpuResult = await client.execute('top -bn1 | grep "Cpu(s)"');
      final cpuUsage = _parseCpuUsage(cpuResult);
      
      // Получаем данные памяти
      final memoryResult = await client.execute('free | grep Mem:');
      final memoryUsage = _parseMemoryUsage(memoryResult);
      
      // Получаем данные диска
      final diskResult = await client.execute('df / | tail -1');
      final diskUsage = _parseDiskUsage(diskResult);
      
      // Получаем uptime
      final uptimeResult = await client.execute('cat /proc/uptime');
      final uptime = _parseUptime(uptimeResult);
      
      // Получаем температуру (если доступно)
      final tempResult = await client.execute(
        'cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null || '
        'cat /sys/class/thermal/thermal_zone1/temp 2>/dev/null || '
        'echo "0"'
      );
      final temperature = _parseTemperature(tempResult);
      
      // Сетевой трафик - получаем полученные байты за последнюю секунду
      final networkResult = await client.execute(
        'cat /proc/net/dev | grep -E "(eth0|ens|wlan)" | head -1'
      );
      final networkUsage = _parseNetworkUsage(networkResult);

      // Получаем hostname для красоты
      final hostnameResult = await client.execute('hostname');
      final serverName = (hostnameResult?.trim().isNotEmpty ?? false) 
          ? hostnameResult!.trim() 
          : config.name;

      // Закрываем соединение
      await client.disconnect();

      return ServerStats(
        serverName: serverName,
        ipAddress: config.host,
        lastUpdate: DateTime.now(),
        cpuUsage: cpuUsage,
        memoryUsage: memoryUsage,
        diskUsage: diskUsage,
        networkUsage: networkUsage,
        temperature: temperature,
        uptime: uptime,
        isOnline: true,
      );
    } catch (e) {
      print('SSH Error for ${config.name}: $e');
      
      // Возвращаем оффлайн статус при ошибке
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
      
      // Пример вывода: "%Cpu(s):  5.3 us,  2.1 sy,  0.0 ni, 92.6 id,  0.0 wa,  0.0 hi,  0.0 si,  0.0 st"
      final match = RegExp(r'(\d+\.\d+)\s+id,').firstMatch(cpuOutput);
      if (match != null) {
        final idle = double.parse(match.group(1)!);
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
      
      // Пример вывода: "Mem:   16304252   4823652    566432   10969948  11474168"
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
      
      // Пример вывода: "/dev/sda1       100G   50G   50G   50% /"
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
        return temp / 1000.0; // преобразуем миллиградусы в градусы
      }
    } catch (e) {
      print('Error parsing temperature: $e');
    }
    return 0;
  }

  double _parseNetworkUsage(String? networkOutput) {
    try {
      if (networkOutput == null || networkOutput.isEmpty) return 0;
      
      // Пример вывода: "eth0: 123456 7890 0 0 0 0 0 0 987654 3210 0 0 0 0 0 0"
      final parts = networkOutput.split(':');
      if (parts.length >= 2) {
        final values = parts[1].trim().split(RegExp(r'\s+'));
        if (values.isNotEmpty) {
          final receivedBytes = double.tryParse(values[0]) ?? 0;
          // Конвертируем байты в Мбиты (1 байт = 8 бит, 1 Мбит = 1,048,576 бит)
          return (receivedBytes * 8) / 1048576;
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

  ServerConfig({
    String? id,
    required this.name,
    required this.host,
    this.port = 22,
    required this.username,
    required this.password,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString();
}