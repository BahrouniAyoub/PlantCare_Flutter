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


class DetailPage extends StatefulWidget {
  final Plant plant;

  const DetailPage({Key? key, required this.plant}) : super(key: key);

  @override
  _DetailPageState createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  // late MqttService mqttService;

  double? latestTemperature;
  double? latestHumidity;

  // 🕓 To store last updated time
  String _lastUpdated = DateTime.now().toLocal().toString().substring(0, 16);

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
      // mqttService = MqttService(onMessageReceived: _handleMqttMessage);
      // mqttService.connect();
    }
  }

  void _handleMqttMessage(String topic, String message) {
    setState(() {
      final now = DateTime.now();
      final timeLabel =
          "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";

      if (topic == 'sensor/temperature') {
        final tempValue = double.tryParse(message) ?? 0;
        latestTemperature = tempValue;
        temperatureData.add({'time': timeLabel, 'value': tempValue});
        if (temperatureData.length > 6) temperatureData.removeAt(0);
      } else if (topic == 'sensor/humidity') {
        final humValue = double.tryParse(message) ?? 0;
        latestHumidity = humValue;
        soilHumidityData.add({'time': timeLabel, 'value': humValue});
        if (soilHumidityData.length > 6) soilHumidityData.removeAt(0);
      }

      _lastUpdated = now.toLocal().toString().substring(0, 16);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    if (!kIsWeb) {
      // mqttService.disconnect();
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
  return Padding(
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

        // Temperature Info
        Row(
          children: [
            const Icon(Icons.thermostat, color: Colors.red),
            const SizedBox(width: 10),
            Text(
              latestTemperature != null
                  ? 'Temperature: ${latestTemperature!.toStringAsFixed(2)} °C'
                  : 'Temperature: waiting for data...',
              style: const TextStyle(fontSize: 18),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Temperature Chart
        temperatureData.isNotEmpty
            ? _buildLineChart(temperatureData, Colors.red)
            : const Text('No temperature data yet.'),
        const SizedBox(height: 30),

        // Humidity Info
        Row(
          children: [
            const Icon(Icons.water_drop, color: Colors.blue),
            const SizedBox(width: 10),
            Text(
              latestHumidity != null
                  ? 'Humidity: ${latestHumidity!.toStringAsFixed(2)} %'
                  : 'Humidity: waiting for data...',
              style: const TextStyle(fontSize: 18),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Humidity Chart
        soilHumidityData.isNotEmpty
            ? _buildLineChart(soilHumidityData, Colors.blue)
            : const Text('No humidity data yet.'),
        const SizedBox(height: 20),

        // Timestamp
        Center(
          child: Text(
            'Last Updated: $_lastUpdated',
            style: const TextStyle(fontSize: 14, color: Colors.grey),
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
