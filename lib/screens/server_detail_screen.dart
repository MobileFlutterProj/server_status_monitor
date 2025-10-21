import 'package:flutter/material.dart';
import '../models/server_stats.dart';

class ServerDetailScreen extends StatelessWidget {
  final ServerStats stats;

  const ServerDetailScreen({super.key, required this.stats});

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
            _buildStatusCard(),
            const SizedBox(height: 16),
            
            // Основные метрики
            _buildMetricsSection(),
            const SizedBox(height: 16),
            
            // Системная информация
            _buildSystemInfoSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
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
                    stats.isOnline ? 'ОНЛАЙН' : 'ОФФЛАЙН',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: stats.isOnline ? Colors.green : Colors.red,
                    ),
                  ),
                  Text(
                    'IP: ${stats.ipAddress}',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ),
            Icon(
              stats.isOnline ? Icons.check_circle : Icons.error,
              color: stats.isOnline ? Colors.green : Colors.red,
              size: 32,
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
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildMetricRow('Процессор (CPU)', '${stats.cpuUsage.toStringAsFixed(1)}%', stats.cpuUsage),
            _buildMetricRow('Память (RAM)', '${stats.memoryUsage.toStringAsFixed(1)}%', stats.memoryUsage),
            _buildMetricRow('Диск', '${stats.diskUsage.toStringAsFixed(1)}%', stats.diskUsage),
            _buildMetricRow('Сеть', '${stats.networkUsage.toStringAsFixed(1)} Мбит/с', stats.networkUsage / 5), // нормализуем для прогресс-бара
            _buildMetricRow('Температура', '${stats.temperature.toStringAsFixed(1)}°C', stats.temperature / 100), // нормализуем для прогресс-бара
          ],
        ),
      ),
    );
  }

  Widget _buildMetricRow(String label, String value, double progress) {
    Color getColor(double value) {
      if (value < 0.7) return Colors.green;
      if (value < 0.85) return Colors.orange;
      return Colors.red;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 16),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: getColor(progress),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: progress.clamp(0, 1),
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(getColor(progress)),
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
            _buildInfoRow('Статус', stats.isOnline ? 'Работает нормально' : 'Недоступен'),
            _buildInfoRow('IP адрес', stats.ipAddress),
          ],
        ),
      ),
    );
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