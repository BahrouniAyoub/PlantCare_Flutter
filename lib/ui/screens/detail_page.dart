import 'dart:async';
import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_onboarding/constants.dart';
import 'package:flutter_onboarding/models/plants.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_onboarding/ui/screens/mqtt_service.dart';
import 'dart:convert';
import 'dart:typed_data';
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

  Future<void> _loadLastHourHistory() async {
    try {
      final now = DateTime.now();
      final oneHourAgo = now.subtract(const Duration(hours: 1));

      final response = await http.get(
        Uri.parse(
          'http://10.0.2.2:5000/api/history/${widget.plant.id}?since=${oneHourAgo.toUtc().toIso8601String()}',
        ),
      );

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
          _lastUpdated = now.toLocal().toString().substring(0, 16);
        });
      } else {
        print('History load error: ${response.body}');
      }
    } catch (e) {
      print('Exception in _loadLastHourHistory: $e');
    }
  }

  // 🕓 To store last updated time
  String _lastUpdated = DateTime.now().toLocal().toString().substring(0, 16);

  Future<void> _loadSensorHistory() async {
    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:5000/api/history/${widget.plant.id}'),
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);

        final tempData = <Map<String, dynamic>>[];
        final humData = <Map<String, dynamic>>[];

        for (var item in data) {
          final DateTime ts = DateTime.parse(item['timestamp']);
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

          // if (temperatureData.isNotEmpty && soilHumidityData.isNotEmpty) {
          //   final tMax = temperatureData.last['value'] as double;
          //   final tMin = (soilHumidityData.last['value'] as double) / 2;
          //   final now = DateTime.now();

          //   recommendedWateringInterval = estimateWateringFrequency(
          //     tMax: tMax,
          //     tMin: tMin,
          //     latitude: 36.8,
          //     dayOfYear: int.parse(DateFormat("D").format(now)),
          //     kc: 0.9,
          //     rootZoneWaterHoldingCapacityMm: 100,
          //   );
          // }
        });
      } else {
        print('Error loading history: ${response.body}');
      }
    } catch (e) {
      print('Exception loading history: $e');
    }
  }

// 🔵 Refresh Sensor Data Manually
  void _refreshSensorData() {
    final random = Random();

    setState(() {
      temperatureData.add({
        'time': '${8 + temperatureData.length * 2}:00',
        'value': 20 + random.nextDouble() * 10,
      });
      soilHumidityData.add({
        'time': '${8 + soilHumidityData.length * 2}:00',
        'value': 50 + random.nextInt(20),
      });

      // Keep max 6 points
      if (temperatureData.length > 6) temperatureData.removeAt(0);
      if (soilHumidityData.length > 6) soilHumidityData.removeAt(0);

      // Update the last updated time
      _lastUpdated = DateTime.now().toLocal().toString().substring(0, 16);
    });
  }

  List<Map<String, dynamic>> temperatureData = [];
  List<Map<String, dynamic>> soilHumidityData = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    if (!kIsWeb) {
      // ✅ Only connect MQTT on Android/iOS

      mqttService = MqttService(
          plantId: widget.plant.id, onMessageReceived: _handleMqttMessage);
      mqttService.connect();
    }
    _loadSensorHistory();
  }

  void _handleMqttMessage(String topic, String message) {
    setState(() {
      final now = DateTime.now();
      final timeLabel =
          "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
      print('MQTT MESSAGE: $topic => $message');

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
      print("Temp: $latestTemperature, Hum: $latestHumidity");

      final result = estimateWateringFrequencyAndAmount(
        tMax: latestTemperature!,
        tMin: latestHumidity! / 2,
        latitude: 36.8,
        dayOfYear: int.parse(DateFormat("D").format(DateTime.now())),
        kc: 0.9,
        rootZoneWaterHoldingCapacityMm: 100,
      );

      recommendedWateringDays = result['days'];
      recommendedWateringAmount = result['amountMm'];

      _lastUpdated = now.toLocal().toString().substring(0, 16);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    if (!kIsWeb) {
      mqttService.disconnect();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool hasSuggestions =
        widget.plant.classification?.suggestions.isNotEmpty ?? false;
    final bool hasDiseaseSuggestions =
        widget.plant.plantHealth?.disease?.suggestions.isNotEmpty ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.plant.name),
        backgroundColor: Constants.primaryColor,
        elevation: 0.0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Basic Info'),
            Tab(text: 'Plant Health'),
            Tab(text: 'Sensors'),
            Tab(text: 'Care Tips'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBasicInfoTab(hasSuggestions),
          _buildPlantHealthTab(hasDiseaseSuggestions),
          _buildSensorDataTab(),
          _buildCareTipsTab(hasSuggestions),
        ],
      ),
    );
  }

  // 🪴 Basic Info
  // Basic Info
  Widget _buildBasicInfoTab(bool hasSuggestions) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.plant.image.isNotEmpty)
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(
                    base64Decode(widget.plant.image
                        .split(',')
                        .last), // Remove the prefix
                    height: 250,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            const SizedBox(height: 20),
            Text(
              widget.plant.name,
              style: TextStyle(
                color: Constants.primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 30.0,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              hasSuggestions
                  ? "Description: ${widget.plant.classification?.suggestions.first.details?.description?.value ?? 'No description available'}"
                  : "Description: No information available",
              style: TextStyle(
                fontSize: 18.0,
                color: Constants.blackColor.withOpacity(0.7),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            if (!kIsWeb &&
                hasSuggestions &&
                (widget.plant.classification?.suggestions.first.similarImages
                        ?.isNotEmpty ??
                    false))
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Similar Images:',
                    style: TextStyle(
                      fontSize: 22.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 150,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: widget.plant.classification?.suggestions.first
                              .similarImages?.length ??
                          0,
                      itemBuilder: (context, index) {
                        final similarImage = widget.plant.classification!
                            .suggestions.first.similarImages![index];
                        return Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              similarImage.urlSmall.isNotEmpty
                                  ? similarImage.urlSmall
                                  : similarImage.url,
                              height: 120,
                              width: 120,
                              fit: BoxFit.cover,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  // Plant Health
  Widget _buildPlantHealthTab(bool hasDiseaseSuggestions) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Health Status: ${(widget.plant.plantHealth?.isHealthy?.binary ?? false) ? 'Healthy' : 'Unhealthy'} "
              "(${((widget.plant.plantHealth?.isHealthy?.probability ?? 0.0) * 100).toStringAsFixed(2)}%)",
              style: TextStyle(
                fontSize: 18.0,
                color: Constants.blackColor.withOpacity(0.7),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            if (hasDiseaseSuggestions)
              ...widget.plant.plantHealth!.disease!.suggestions.map(
                (suggestion) => Padding(
                  padding: const EdgeInsets.only(bottom: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Disease: ${suggestion.name}",
                        style: TextStyle(
                          fontSize: 18.0,
                          color: Constants.blackColor.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        "Treatment: ${suggestion.details?.treatment ?? 'Unknown'}",
                        style: TextStyle(
                          fontSize: 16.0,
                          color: Constants.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              const Text('No disease information available'),
          ],
        ),
      ),
    );
  }

  // 🪴 Live Sensor Graph
  Widget _buildSensorDataTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🌿 Live Sensor Readings',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 20),
          TextButton.icon(
            onPressed: _loadLastHourHistory,
            icon: const Icon(Icons.history),
            label: const Text('Show Last Hour History'),
          ),
          const SizedBox(height: 20),

          // Temperature Info + Chart + History
          const SizedBox(height: 20),
          Row(children: [
            const Icon(Icons.thermostat, color: Colors.red),
            const SizedBox(width: 10),
            Text(
              latestTemperature != null
                  ? 'Temperature: ${latestTemperature!.toStringAsFixed(2)} °C'
                  : 'Temperature: waiting for data...',
              style: const TextStyle(fontSize: 18),
            ),
          ]),
          const SizedBox(height: 10),
          temperatureData.isNotEmpty
              ? _buildLineChart(temperatureData, Colors.red)
              : const Text('No live temperature data yet.'),
          const SizedBox(height: 10),
          temperatureData.isNotEmpty
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('📈 Temperature History (Last Hour):'),
                    ...temperatureData.map((entry) => Text(
                        "🕒 ${entry['time']} → 🌡️ ${entry['value'].toStringAsFixed(2)} °C")),
                  ],
                )
              : const Text('No temperature history yet.'),

          const SizedBox(height: 10),

          // Humidity Info + Chart + History
          const SizedBox(height: 30),
          Row(children: [
            const Icon(Icons.water_drop, color: Colors.blue),
            const SizedBox(width: 10),
            Text(
              latestHumidity != null
                  ? 'Humidity: ${latestHumidity!.toStringAsFixed(2)} %'
                  : 'Humidity: waiting for data...',
              style: const TextStyle(fontSize: 18),
            ),
          ]),
          const SizedBox(height: 10),
          soilHumidityData.isNotEmpty
              ? _buildLineChart(soilHumidityData, Colors.blue)
              : const Text('No live humidity data yet.'),
          const SizedBox(height: 10),
          soilHumidityData.isNotEmpty
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('📉 Humidity History (Last Hour):'),
                    ...soilHumidityData.map((entry) => Text(
                        "🕒 ${entry['time']} → 💧 ${entry['value'].toStringAsFixed(2)} %")),
                  ],
                )
              : const Text('No humidity history yet.'),

          // Timestamp
          Center(
            child: Text(
              'Last Updated: $_lastUpdated',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ),

          if (recommendedWateringDays != null &&
              recommendedWateringAmount != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                '💧 Recommended Watering: Every ${recommendedWateringDays!.toStringAsFixed(1)} days with ${recommendedWateringAmount!.toStringAsFixed(0)} mm of water',
                style: const TextStyle(
                    fontSize: 16,
                    color: Colors.green,
                    fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }

// 🔵 Generate Line Chart Data (Helper Function)
  LineChartData _buildLineChartData(
      List<Map<String, dynamic>> data, Color lineColor) {
    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        horizontalInterval: 5,
        verticalInterval: 1,
        getDrawingHorizontalLine: (_) =>
            FlLine(color: Colors.grey.shade300, strokeWidth: 1),
        getDrawingVerticalLine: (_) =>
            FlLine(color: Colors.grey.shade300, strokeWidth: 1),
      ),
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 32,
            interval: 1,
            getTitlesWidget: (value, _) {
              int index = value.toInt();
              if (index >= 0 && index < data.length) {
                return Text(
                  data[index]['time'],
                  style: const TextStyle(fontSize: 12),
                );
              }
              return const Text('');
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 32,
            getTitlesWidget: (value, _) => Text('${value.toInt()}'),
          ),
        ),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border.all(color: Colors.black12),
      ),
      minX: 0,
      maxX: (data.length - 1).toDouble(),
      lineBarsData: [
        LineChartBarData(
          spots: data
              .asMap()
              .entries
              .map((e) => FlSpot(
                  e.key.toDouble(), (e.value['value'] as num).toDouble()))
              .toList(),
          isCurved: true,
          gradient: LinearGradient(
            colors: [lineColor.withOpacity(0.8), lineColor.withOpacity(0.2)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [lineColor.withOpacity(0.2), Colors.transparent],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          dotData: FlDotData(show: true),
          isStrokeCapRound: true,
          barWidth: 4,
        ),
      ],
    );
  }

  // Graph Builder
  Widget _buildLineChart(List<Map<String, dynamic>> data, Color lineColor) {
    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: true),
          borderData: FlBorderData(show: true),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, _) {
                  int index = value.toInt();
                  if (index >= 0 && index < data.length) {
                    return Text(data[index]['time']);
                  }
                  return const Text('');
                },
              ),
            ),
          ),
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

  // 🪴 Care Tips with Cute Icons
  Widget _buildCareTipsTab(bool hasSuggestions) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CareTipFeature(
              emoji: "☀️",
              title: 'Best Light Condition',
              description: widget.plant.classification?.suggestions.first
                      .details?.bestLightCondition ??
                  'Unknown',
            ),
            const SizedBox(height: 10),
            CareTipFeature(
              emoji: "🌱",
              title: 'Best Soil Type',
              description: widget.plant.classification?.suggestions.first
                      .details?.bestSoilType ??
                  'Unknown',
            ),
            const SizedBox(height: 10),
            CareTipFeature(
              emoji: "💧",
              title: 'Best Watering',
              description: widget.plant.classification?.suggestions.first
                      .details?.bestWatering ??
                  'Unknown',
            ),
            const SizedBox(height: 10),
            CareTipFeature(
              emoji: "🌸",
              title: 'Common Uses',
              description: widget.plant.classification?.suggestions.first
                      .details?.commonUses ??
                  'Unknown',
            ),
          ],
        ),
      ),
    );
  }
}

// Care Tip Widget with Emoji
class CareTipFeature extends StatelessWidget {
  final String emoji;
  final String title;
  final String description;

  const CareTipFeature(
      {Key? key,
      required this.emoji,
      required this.title,
      required this.description})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          emoji,
          style: const TextStyle(fontSize: 24),
        ),
        const SizedBox(width: 8),
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
              Text(
                description,
                style: TextStyle(fontSize: 16, color: Constants.blackColor),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// 🧩 Extension to get the last N elements from a list
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
    'amountMm': rootZoneWaterHoldingCapacityMm,
  };
}
