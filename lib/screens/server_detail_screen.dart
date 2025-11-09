import 'package:flutter/material.dart';
import '../models/server_stats.dart';

class ServerDetailScreen extends StatelessWidget {
  final ServerStats stats;
  final VoidCallback? onRefresh;

  const ServerDetailScreen({
    super.key, 
    required this.stats,
    this.onRefresh,
  });

  bool get _hasMetricsData {
    return stats.cpuUsage > 0 || 
           stats.memoryUsage > 0 || 
           stats.diskUsage > 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(stats.serverName),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Статус сервера
            _buildServerStatusCard(),
            const SizedBox(height: 16),
            
            // Основные метрики или сообщение об отсутствии данных
            if (_hasMetricsData) ...[
              _buildMetricsSection(),
              const SizedBox(height: 16),
            ] else ...[
              _buildNoDataSection(),
              const SizedBox(height: 16),
            ],
            
            // Системная информация (всегда показываем)
            _buildSystemInfoSection(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: onRefresh,
        tooltip: 'Обновить данные',
        child: const Icon(Icons.refresh),
      ),
    );
  }

  Widget _buildServerStatusCard() {
    String statusText;
    Color statusColor;
    IconData statusIcon;

    if (stats.isOnline) {
      statusText = 'ОНЛАЙН';
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
    } else if (stats.isCachedData) {
      statusText = 'ОФФЛАЙН (КЕШИРОВАННЫЕ ДАННЫЕ)';
      statusColor = Colors.orange;
      statusIcon = Icons.history;
    } else {
      statusText = 'ОФФЛАЙН';
      statusColor = Colors.red;
      statusIcon = Icons.error;
    }

    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: statusColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                  Text(
                    'IP: ${stats.ipAddress}',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  if (stats.isCachedData) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Данные обновлены: ${stats.lastUpdateFormatted}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.orange,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              statusIcon,
              color: statusColor,
              size: 32,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoDataSection() {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(
              Icons.data_exploration,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              'Данные отсутствуют',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Нет доступных метрик для отображения.\n'
              'Сервер может быть недоступен или данные еще не были получены.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 20),
            if (onRefresh != null)
              ElevatedButton.icon(
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh),
                label: const Text('Попробовать снова'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsSection() {
  return Card(
    elevation: 3,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Метрики системы',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          if (stats.cpuUsage > 0)
            _buildUsageMetric('Процессор (CPU)', '${stats.cpuUsage.toStringAsFixed(1)}%', stats.cpuUsage),
          if (stats.memoryUsage > 0)
            _buildUsageMetric('Память (RAM)', '${stats.memoryUsage.toStringAsFixed(1)}%', stats.memoryUsage),
          if (stats.diskUsage > 0)
            _buildUsageMetric('Диск', '${stats.diskUsage.toStringAsFixed(1)}%', stats.diskUsage),
          if (stats.networkUsage > 0)
            _buildNetworkMetric('Сеть', '${stats.networkUsage.toStringAsFixed(1)} Мбит', stats.networkUsage),
          if (stats.temperature > 0)
            _buildTempMetric('Температура', '${stats.temperature.toStringAsFixed(1)}°C', stats.temperature),
        ],
      ),
    ),
  );
}

  // Для CPU/RAM/Disk
  Widget _buildUsageMetric(String label, String value, double percent) {
    final color = _getUsageColor(percent);
    return _buildMetricRow(label, value, percent, color);
  }

  // Для температуры
  Widget _buildTempMetric(String label, String value, double celsius) {
    final color = _getTempColor(celsius);
    // Прогресс-бар для температуры не используется, но если нужен — можно нормализовать до 0..1 (см. ниже)
    return _buildMetricRow(label, value, celsius.clamp(0, 100) / 100, color);
  }

  // Для сети — без цвета или с фиксированным цветом
  Widget _buildNetworkMetric(String label, String value, double mbps) {
    return _buildMetricRow(label, value, mbps.clamp(0, 100) / 100, Colors.blue); // или без прогресса
  }

  Color _getUsageColor(double percent) {
    if (percent < 70) return Colors.green;
    if (percent < 85) return Colors.orange;
    return Colors.red;
  }

  Color _getTempColor(double celsius) {
    if (celsius < 50) return Colors.green;
    if (celsius < 70) return Colors.orange;
    return Colors.red;
  }

  // Обобщённый row
  Widget _buildMetricRow(String label, String value, double progressValue, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 16)),
              Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: progressValue,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemInfoSection() {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Системная информация',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Время работы', stats.uptimeFormatted),
            _buildInfoRow('Последнее обновление', stats.lastUpdateFormatted),
            _buildInfoRow('Статус', _getStatusText()),
            _buildInfoRow('IP адрес', stats.ipAddress),
            if (stats.isCachedData)
              _buildInfoRow('Тип данных', 'Кешированные (исторические)'),
          ],
        ),
      ),
    );
  }

  String _getStatusText() {
    if (stats.isOnline) {
      return 'Работает нормально';
    } else if (stats.isCachedData) {
      return 'Недоступен (показываются последние данные)';
    } else {
      return 'Недоступен';
    }
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}