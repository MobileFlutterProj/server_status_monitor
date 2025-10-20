import 'package:flutter/material.dart';
import '../models/server_stats.dart';

class ServerCard extends StatelessWidget {
  final ServerStats stats;
  final VoidCallback? onTap;

  const ServerCard({
    super.key,
    required this.stats,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Индикатор статуса
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: stats.isOnline ? Colors.green : Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 16),
              // Информация о сервере - ИСПРАВЛЕННЫЕ НАЗВАНИЯ ПОЛЕЙ
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stats.serverName, // было: server.name
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${stats.ipAddress}:22', // было: server.url и server.port
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Последняя проверка: ${stats.lastUpdateFormatted}', // было: server.lastChecked
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
              // Иконка статуса
              Icon(
                stats.isOnline ? Icons.check_circle : Icons.error,
                color: stats.isOnline ? Colors.green : Colors.red,
              ),
            ],
          ),
        ),
      ),
    );
  }
}