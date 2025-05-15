import 'package:flutter/material.dart';

class SensorHistoryPage extends StatelessWidget {
  final List<Map<String, dynamic>> temperatureData;
  final List<Map<String, dynamic>> humidityData;

  const SensorHistoryPage({
    Key? key,
    required this.temperatureData,
    required this.humidityData,
  }) : super(key: key);

  Widget _buildSensorCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<Map<String, dynamic>> data,
    required String unit,
    required String emptyMessage,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: iconColor),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            if (data.isEmpty)
              Text(emptyMessage)
            else
              ListView.separated(
                itemCount: data.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                separatorBuilder: (_, __) => const Divider(height: 10),
                itemBuilder: (context, index) {
                  final entry = data[index];
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "${entry['value'].toStringAsFixed(2)} $unit",
                        style: const TextStyle(fontSize: 16),
                      ),
                      Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.access_time, size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              entry['time'],
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      )
                    ],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sensor History'),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildSensorCard(
              title: '🌡️ Temperature Readings',
              icon: Icons.thermostat,
              iconColor: Colors.redAccent,
              data: temperatureData,
              unit: '°C',
              emptyMessage: 'No temperature data available.',
            ),
            _buildSensorCard(
              title: '💧 Humidity Readings',
              icon: Icons.water_drop,
              iconColor: Colors.blueAccent,
              data: humidityData,
              unit: '%',
              emptyMessage: 'No humidity data available.',
            ),
          ],
        ),
      ),
    );
  }
}
