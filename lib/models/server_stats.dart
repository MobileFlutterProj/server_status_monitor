class ServerStats {
  final String serverName;
  final String ipAddress;
  final DateTime lastUpdate;
  final double cpuUsage;
  final double memoryUsage;
  final double diskUsage;
  final double networkUsage;
  final double temperature;
  final int uptime;
  final bool isOnline;

  ServerStats({
    required this.serverName,
    required this.ipAddress,
    required this.lastUpdate,
    required this.cpuUsage,
    required this.memoryUsage,
    required this.diskUsage,
    required this.networkUsage,
    required this.temperature,
    required this.uptime,
    required this.isOnline,
  });

  ServerStats copyWith({
    String? serverName,
    String? ipAddress,
    DateTime? lastUpdate,
    double? cpuUsage,
    double? memoryUsage,
    double? diskUsage,
    double? networkUsage,
    double? temperature,
    int? uptime,
    bool? isOnline,
  }) {
    return ServerStats(
      serverName: serverName ?? this.serverName,
      ipAddress: ipAddress ?? this.ipAddress,
      lastUpdate: lastUpdate ?? this.lastUpdate,
      cpuUsage: cpuUsage ?? this.cpuUsage,
      memoryUsage: memoryUsage ?? this.memoryUsage,
      diskUsage: diskUsage ?? this.diskUsage,
      networkUsage: networkUsage ?? this.networkUsage,
      temperature: temperature ?? this.temperature,
      uptime: uptime ?? this.uptime,
      isOnline: isOnline ?? this.isOnline,
    );
  }

  String get uptimeFormatted {
    final days = uptime ~/ (24 * 3600);
    final hours = (uptime % (24 * 3600)) ~/ 3600;
    final minutes = (uptime % 3600) ~/ 60;
    
    if (days > 0) {
      return '${days}d ${hours}h ${minutes}m';
    } else if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  String get lastUpdateFormatted {
    final now = DateTime.now();
    final difference = now.difference(lastUpdate);
    
    if (difference.inMinutes < 1) {
      return 'Только что';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} мин назад';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} ч назад';
    } else {
      return '${difference.inDays} дн назад';
    }
  }
}