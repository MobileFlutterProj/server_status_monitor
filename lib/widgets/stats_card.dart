import 'package:flutter/material.dart';
import '../models/server_stats.dart';
import 'circular_progress.dart';

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

  bool get _hasMetricsData {
    return stats.cpuUsage > 0 || 
           stats.memoryUsage > 0 || 
           stats.diskUsage > 0 ||
           stats.uptime > 0;
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
                  // Индикатор статуса
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: stats.isOnline 
                          ? Colors.green 
                          : (_hasMetricsData ? Colors.orange : Colors.red),
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
                  // Иконка статуса
                  _buildStatusIndicator(),
                ],
              ),
              
              // Бейдж кешированных данных
              if (stats.isCachedData) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.schedule,
                        size: 14,
                        color: Colors.orange,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Кешированные данные',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              // Бейдж отсутствия данных
              if (!_hasMetricsData && !stats.isOnline) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 14,
                        color: Colors.grey,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Данные отсутствуют',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              const SizedBox(height: 16),
              
              // Контент в зависимости от наличия данных
              if (!_hasMetricsData && !stats.isOnline) 
                _buildNoDataContent()
              else 
                _buildMetricsContent(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIndicator() {
    if (stats.isOnline) {
      return const Icon(Icons.check_circle, color: Colors.green);
    } else if (_hasMetricsData) {
      return const Icon(Icons.history, color: Colors.orange);
    } else {
      return const Icon(Icons.error, color: Colors.red);
    }
  }

  Widget _buildNoDataContent() {
    return Column(
      children: [
        const Center(
          child: Text(
            'ДАННЫЕ ОТСУТСТВУЮТ',
            style: TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Нажмите для попытки подключения',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        // Кнопка для быстрой попытки подключения
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: onTap,
            icon: const Icon(Icons.refresh),
            label: const Text('Обновить данные'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.blue,
              side: const BorderSide(color: Colors.blue),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricsContent() {
    return Column(
      children: [
        // Основные метрики
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            CircularProgressWidget(
              value: stats.cpuUsage,
              label: 'CPU',
              color: _getColorForValue(stats.cpuUsage, 'cpu'),
            ),
            CircularProgressWidget(
              value: stats.memoryUsage,
              label: 'RAM',
              color: _getColorForValue(stats.memoryUsage, 'memory'),
            ),
            CircularProgressWidget(
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
            if (stats.temperature > 0)
              _buildInfoItem(
                '🌡️ Temp', 
                '${stats.temperature.toStringAsFixed(1)}°C',
                _getColorForValue(stats.temperature, 'temperature'),
              ),
            if (stats.networkUsage > 0)
              _buildInfoItem(
                '📶 Network', 
                '${stats.networkUsage.toStringAsFixed(1)} Mb',
                Colors.blue,
              ),
            if (stats.uptime > 0)
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
            _buildInfoItem(
              '📊 Статус', 
              stats.isOnline ? 'Онлайн' : 'Офлайн',
              stats.isOnline ? Colors.green : Colors.red,
            ),
          ],
        ),
      ],
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