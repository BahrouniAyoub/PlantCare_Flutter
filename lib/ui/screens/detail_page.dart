// Enhanced DetailPage with better UI design
import 'dart:async';
import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_onboarding/constants.dart';
import 'package:flutter_onboarding/models/plants.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_onboarding/ui/screens/mqtt_service.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class DetailPage extends StatefulWidget {
  final Plant plant;

  const DetailPage({Key? key, required this.plant}) : super(key: key);

  @override
  _DetailPageState createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late MqttService mqttService;
  double? latestTemperature;
  double? latestHumidity;
  double? recommendedWateringDays;
  double? recommendedWateringAmount;
  bool isAutoIrrigationEnabled = false;
  bool isManualIrrigationOn = false;
  String _lastUpdated = DateTime.now().toLocal().toString().substring(0, 16);

  List<Map<String, dynamic>> temperatureData = [];
  List<Map<String, dynamic>> soilHumidityData = [];



  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    // print('🪴 Plant ID: ${widget.plant.id}');
    if (!kIsWeb) {
      mqttService = MqttService(
        plantId: widget.plant.id,
        onMessageReceived: _handleMqttMessage,
      );
      mqttService.connect();
    }
    _loadSensorHistory();
  }

  void _handleMqttMessage(String topic, String message) {
    setState(() {
      final now = DateTime.now();
      final timeLabel =
          "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
      if (topic == 'sensor/${widget.plant.id}/temp') {
        final tempValue = double.tryParse(message) ?? 0;
        latestTemperature = tempValue;
        temperatureData.add({'time': timeLabel, 'value': tempValue});
        if (temperatureData.length > 6) temperatureData.removeAt(0);
      } else if (topic == 'sensor/${widget.plant.id}/hum') {
        final humValue = double.tryParse(message) ?? 0;
        latestHumidity = humValue;
        soilHumidityData.add({'time': timeLabel, 'value': humValue});
        if (soilHumidityData.length > 6) soilHumidityData.removeAt(0);
      }
      if (latestTemperature != null && latestHumidity != null) {
        final result = estimateWateringFrequencyAndAmount(
          tMax: latestTemperature!,
          tMin: latestHumidity! / 2,
          latitude: 36.8,
          dayOfYear: int.parse(DateFormat("D").format(now)),
          kc: 0.5,
          rootZoneWaterHoldingCapacityMm: 100,
        );
        recommendedWateringDays = result['days'];
        recommendedWateringAmount = result['amountMm'];
      }
      _lastUpdated = now.toLocal().toString().substring(0, 16);
    });
  }

  Future<void> _loadSensorHistory() async {
    try {
      final response = await http.get(
          Uri.parse('http://10.0.2.2:5000/api/history/${widget.plant.id}'));
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        final tempData = <Map<String, dynamic>>[];
        final humData = <Map<String, dynamic>>[];

        for (var item in data) {
          final ts = DateTime.parse(item['timestamp']);
          final label =
              "${ts.hour.toString().padLeft(2, '0')}:${ts.minute.toString().padLeft(2, '0')}";
          if (item['sensorType'] == 'temp') {
            tempData.add({'time': label, 'value': item['value']});
          } else if (item['sensorType'] == 'hum') {
            humData.add({'time': label, 'value': item['value']});
          }
        }

        setState(() {
          temperatureData = tempData.takeLast(6).toList();
          soilHumidityData = humData.takeLast(6).toList();
        });
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  
  @override
  void dispose() {
    _tabController.dispose();
    if (!kIsWeb) mqttService.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.plant.name),
        backgroundColor: Colors.green,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.info), text: 'Info'),
            Tab(icon: Icon(Icons.health_and_safety), text: 'Health'),
            Tab(icon: Icon(Icons.sensors), text: 'Sensors'),
            Tab(icon: Icon(Icons.tips_and_updates), text: 'Care'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildInfoTab(),
          _buildHealthTab(),
          _buildSensorTab(),
          _buildCareTipsTab(),
        ],
      ),
    );
  }

  Widget _buildInfoTab() {
    final suggestions = widget.plant.classification?.suggestions;
    final description = suggestions?.isNotEmpty == true
        ? suggestions!.first.details?.description?.value ??
            'No description available'
        : 'No description available';

    final similarImages = suggestions?.first.similarImages;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 3,
          child: Column(
            children: [
              if (widget.plant.image.isNotEmpty)
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(12)),
                  child: Image.memory(
                    base64Decode(widget.plant.image.split(',').last),
                    height: 250,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ListTile(
                title: Text(widget.plant.name,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold)),
                subtitle: Text(description),
              ),
              SwitchListTile(
                title: const Text('Irrigation'),
                subtitle: Text(isManualIrrigationOn ? 'ON' : 'OFF'),
                value: isManualIrrigationOn,
                onChanged: (val) {
                  setState(() => isManualIrrigationOn = val);
                },
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/chat');
                },
                child: const Text('🧠 Ask the AI'),
              ),
              if (similarImages != null && similarImages.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Similar Images',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 100,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: similarImages.length,
                          itemBuilder: (context, index) {
                            final image = similarImages[index];
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  image.urlSmall.isNotEmpty
                                      ? image.urlSmall
                                      : image.url,
                                  height: 100,
                                  width: 100,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHealthTab() {
    final health = widget.plant.plantHealth;
    final isHealthy = health?.isHealthy?.binary ?? false;
    final probability =
        ((health?.isHealthy?.probability ?? 0.0) * 100).toStringAsFixed(1);

    final diseaseSuggestions = health?.disease?.suggestions ?? [];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: ListTile(
            title: Text(
                "Overall Health: ${isHealthy ? "Healthy ✅" : "Unhealthy ❌"}"),
            subtitle: Text("Confidence: $probability%"),
          ),
        ),
        const SizedBox(height: 12),
        ...diseaseSuggestions.map((s) => Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                title: Text("Disease: ${s.name}"),
                subtitle:
                    Text("Treatment: ${s.details?.treatment ?? 'Unknown'}"),
              ),
            )),
        if (diseaseSuggestions.isEmpty)
          const Center(child: Text("No disease information available.")),
      ],
    );
  }

  Widget _buildSensorTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSensorCard(
          label: "🌡️ Temperature",
          latest: latestTemperature,
          data: temperatureData,
          color: Colors.red,
        ),
        const SizedBox(height: 12),
        if (temperatureData.isNotEmpty)
          ...temperatureData.map((entry) => Text(
              "🕒 ${entry['time']} → 🌡️ ${entry['value'].toStringAsFixed(2)} °C")),
        const SizedBox(height: 24),
        _buildSensorCard(
          label: "💧 Humidity",
          latest: latestHumidity,
          data: soilHumidityData,
          color: Colors.blue,
        ),
        const SizedBox(height: 12),
        if (soilHumidityData.isNotEmpty)
          ...soilHumidityData.map((entry) => Text(
              "🕒 ${entry['time']} → 💧 ${entry['value'].toStringAsFixed(2)} %")),
        const SizedBox(height: 24),
        Center(child: Text('Last Updated: $_lastUpdated')),
      ],
    );
  }

  Widget _buildSensorCard({
    required String label,
    required double? latest,
    required List<Map<String, dynamic>> data,
    required Color color,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 8),
            Text(latest != null
                ? "Current: ${latest.toStringAsFixed(2)}"
                : "Waiting for data..."),
            const SizedBox(height: 10),
            data.isNotEmpty
                ? _buildLineChart(data, color)
                : const Text("No data yet"),
          ],
        ),
      ),
    );
  }

  Widget _buildCareTipsTab() {
    final details = widget.plant.classification?.suggestions.first.details;
    return details != null
        ? ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                color: Colors.lightBlue.shade50,
                margin: const EdgeInsets.symmetric(vertical: 10),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('💧 AI-Based Watering Suggestion',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(
                        recommendedWateringDays != null &&
                                recommendedWateringAmount != null
                            ? '• Every ${recommendedWateringDays!.toStringAsFixed(1)} days\n• ${recommendedWateringAmount!.toStringAsFixed(0)} mm per watering'
                            : 'ℹ️ Data is being collected... watering suggestion will appear soon.',
                        style: const TextStyle(fontSize: 15),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 10),

               CareTipFeature(
                   emoji: "☀️",
                   title: "Best Light",
                   description: details.bestLightCondition ?? "Unknown"),
               CareTipFeature(
                   emoji: "🌱",
                   title: "Best Soil",
                   description: details.bestSoilType ?? "Unknown"),
               CareTipFeature(
                   emoji: "💧",
                   title: "Best Watering",
                   description: details.bestWatering ?? "Unknown"),
               CareTipFeature(
                   emoji: "🌸",
                   title: "Common Uses",
                   description: details.commonUses ?? "Unknown"),
            ],
          )
        : const Center(child: Text("No care tips available."));
  }

  Widget _buildRecommendationCard() {
    return Card(
      color: Colors.green.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: recommendedWateringDays != null &&
                recommendedWateringAmount != null
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('💧 AI Watering Recommendation',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  SizedBox(height: 6),
                  Text(
                    '• Every ${recommendedWateringDays!.toStringAsFixed(1)} days',
                    style: const TextStyle(fontSize: 15),
                  ),
                  Text(
                    '• ${recommendedWateringAmount!.toStringAsFixed(0)} mm per watering',
                    style: const TextStyle(fontSize: 15),
                  ),
                ],
              )
            : Text('ℹ️ Waiting for sensor data...'),
      ),
    );
  }

  Widget _buildLineChart(List<Map<String, dynamic>> data, Color lineColor) {
    return SizedBox(
      height: 150,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: true),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: data
                  .asMap()
                  .entries
                  .map((e) => FlSpot(
                      e.key.toDouble(), (e.value['value'] as num).toDouble()))
                  .toList(),
              isCurved: true,
              color: lineColor,
              barWidth: 3,
              dotData: FlDotData(show: true),
            ),
          ],
        ),
      ),
    );
  }
}

extension ListTakeLast<T> on List<T> {
  Iterable<T> takeLast(int n) => skip(length > n ? length - n : 0);
}

Map<String, double> estimateWateringFrequencyAndAmount({
  required double tMin,
  required double tMax,
  required double latitude,
  required int dayOfYear,
  required double kc,
  required double rootZoneWaterHoldingCapacityMm,
}) {
  final tMean = (tMax + tMin) / 2;
  final phi = latitude * pi / 180;
  final dr = 1 + 0.033 * cos(2 * pi * dayOfYear / 365);
  final delta = 0.409 * sin(2 * pi * dayOfYear / 365 - 1.39);
  final ws = acos(-tan(phi) * tan(delta));
  final ra = (24 * 60 / pi) *
      0.0820 *
      dr *
      (ws * sin(phi) * sin(delta) + cos(phi) * cos(delta) * sin(ws));
  final et0 = 0.0023 * (tMean + 17.8) * sqrt(tMax - tMin) * ra;
  final etc = et0 * kc;
  final daysBetweenWatering = rootZoneWaterHoldingCapacityMm / etc;
  return {
    'days': daysBetweenWatering,
    'amountMm': rootZoneWaterHoldingCapacityMm
  };
}

class CareTipFeature extends StatelessWidget {
  final String emoji;
  final String title;
  final String description;

  const CareTipFeature({
    Key? key,
    required this.emoji,
    required this.title,
    required this.description,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(fontSize: 15),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
