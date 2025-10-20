import 'package:flutter/material.dart';
import '../models/server_stats.dart';
import 'circular_progress.dart'; // Убедитесь, что переименовали файл

class StatsCard extends StatelessWidget {
  final ServerStats stats;
  final VoidCallback? onTap;

  const StatsCard({
    super.key,
    required this.stats,
    this.onTap,
  });

  Color _getColorForValue(double value, String type) {
    if (type == 'temperature') {
      if (value < 50) return Colors.green;
      if (value < 70) return Colors.orange;
      return Colors.red;
    }
    
    if (value < 70) return Colors.green;
    if (value < 85) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.all(8),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Заголовок с статусом
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: stats.isOnline ? Colors.green : Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          stats.serverName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          stats.ipAddress,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    stats.isOnline ? Icons.check_circle : Icons.error,
                    color: stats.isOnline ? Colors.green : Colors.red,
                  ),
                ],
              ),
              
              if (!stats.isOnline) ...[
                const SizedBox(height: 16),
                const Center(
                  child: Text(
                    'СЕРВЕР НЕДОСТУПЕН',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ] else ...[
                const SizedBox(height: 16),
                
                // Основные метрики
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    CircularProgressWidget( // Изменили название
                      value: stats.cpuUsage,
                      label: 'CPU',
                      color: _getColorForValue(stats.cpuUsage, 'cpu'),
                    ),
                    CircularProgressWidget( // Изменили название
                      value: stats.memoryUsage,
                      label: 'RAM',
                      color: _getColorForValue(stats.memoryUsage, 'memory'),
                    ),
                    CircularProgressWidget( // Изменили название
                      value: stats.diskUsage,
                      label: 'Disk',
                      color: _getColorForValue(stats.diskUsage, 'disk'),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Дополнительная информация
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    _buildInfoItem(
                      '🌡️ Temp', 
                      '${stats.temperature.toStringAsFixed(1)}°C',
                      _getColorForValue(stats.temperature, 'temperature'),
                    ),
                    _buildInfoItem(
                      '📶 Network', 
                      '${stats.networkUsage.toStringAsFixed(1)} Mb/s',
                      Colors.blue,
                    ),
                    _buildInfoItem(
                      '⏱️ Uptime', 
                      stats.uptimeFormatted,
                      Colors.purple,
                    ),
                    _buildInfoItem(
                      '🕒 Updated', 
                      stats.lastUpdateFormatted,
                      Colors.grey,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}