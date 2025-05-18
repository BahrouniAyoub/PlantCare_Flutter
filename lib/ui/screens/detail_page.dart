// Enhanced DetailPage with better UI design
import 'dart:async';
import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_onboarding/constants.dart';
import 'package:flutter_onboarding/main.dart';
import 'package:flutter_onboarding/models/plants.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_onboarding/ui/screens/mqtt_service.dart';
import 'package:flutter_onboarding/ui/screens/sensor_history_page.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_onboarding/services/api_server.dart';

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

  bool _isAutoIrrigation = false;
  bool _isWateringNow = false;
  bool? _needsWater;

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

  void _handleMqttMessage(String topic, String message) async {
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

      final nextWatering =
          now.add(Duration(days: recommendedWateringDays!.round()));
      await saveLastWateringDate(now);
      await scheduleWateringReminder(nextWatering,
          plantName: widget.plant.name);
      await _fetchWateringPrediction();
    }

    setState(() {
      _lastUpdated = now.toLocal().toString().substring(0, 16);
    });
  }

  Future<void> saveLastWateringDate(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'lastWatering_${widget.plant.id}', date.toIso8601String());
  }

  Future<DateTime?> getLastWateringDate() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString('lastWatering_${widget.plant.id}');
    return stored != null ? DateTime.tryParse(stored) : null;
  }

  Future<void> scheduleWateringReminder(DateTime dateTime,
      {required String plantName}) async {
    const androidDetails = AndroidNotificationDetails(
      'watering_channel',
      'Watering Notifications',
      channelDescription: 'Reminders to water your plants',
      importance: Importance.max,
      priority: Priority.high,
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    await notificationsPlugin.show(
      0, // Notification ID
      '💧 Time to Water',
      '🚨 It’s time to water your $plantName!',
      notificationDetails,
    );
  }

  Future<void> _fetchWateringPrediction() async {
    if (latestTemperature == null || latestHumidity == null) return;

    final result = await ApiService.getWateringRecommendation(
      soilMoisture: latestTemperature!,
      temperature: latestHumidity!,
      soilHumidity: 75,
      ph: 6.5,
      rainfall: 0,
      airHumidity: 65,
    );

    setState(() {
      _needsWater = result;
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

  void _enableAutoIrrigation() {
    // Start listening to sensor data for auto decisions
    mqttService.subscribe('auto/${widget.plant.id}');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Automatic irrigation enabled')),
    );
  }

  void _disableAutoIrrigation() {
    // Stop auto watering logic
    mqttService.unsubscribe('auto/${widget.plant.id}');
  }

  Future<void> _startManualWatering() async {
    setState(() => _isWateringNow = true);

    // Send command to device
    await mqttService.publish(
      'actuator/${widget.plant.id}/water',
      '250', // Default manual amount or let user specify
    );

    // Simulate watering time
    await Future.delayed(const Duration(seconds: 5));

    setState(() => _isWateringNow = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Manual watering completed')),
    );
  }

  String _getNextWateringTime() {
    return recommendedWateringDays != null
        ? DateFormat('MMM dd, hh:mm a').format(DateTime.now()
            .add(Duration(days: recommendedWateringDays!.round())))
        : 'Calculating...';
  }

  Widget _buildInfoTab() {
    final suggestions = widget.plant.classification?.suggestions;
    final description = suggestions?.isNotEmpty == true
        ? suggestions!.first.details?.description?.value ??
            'No description available'
        : 'No description available';

    final similarImages = suggestions?.first.similarImages;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Plant Card with Image and Basic Info
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.plant.image.isNotEmpty)
                  Container(
                    height: 220,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: MemoryImage(
                          base64Decode(widget.plant.image.split(',').last),
                        ),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.plant.name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[700],
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Irrigation Control Section
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Irrigation Control',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Mode Toggle
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Irrigation Mode',
                          style: TextStyle(fontSize: 16),
                        ),
                        Switch(
                          value: _isAutoIrrigation,
                          onChanged: (value) {
                            setState(() {
                              _isAutoIrrigation = value;
                              if (value) {
                                _enableAutoIrrigation();
                              } else {
                                _disableAutoIrrigation();
                              }
                            });
                          },
                          activeColor: Colors.green,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Mode-specific Controls
                  if (_isAutoIrrigation)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.autorenew,
                                  color: Colors.green, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Automatic Mode',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Next watering: ${_getNextWateringTime()}',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    )
                  else
                    ElevatedButton.icon(
                      icon: _isWateringNow
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.water_drop, size: 20),
                      label: Text(
                        _isWateringNow ? 'Watering in Progress' : 'Water Now',
                        style: const TextStyle(fontSize: 16),
                      ),
                      onPressed: _isWateringNow ? null : _startManualWatering,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Similar Images Section
          if (similarImages != null && similarImages.isNotEmpty) ...[
            const Text(
              'Similar Plants',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: similarImages.length,
                itemBuilder: (context, index) {
                  final image = similarImages[index];
                  return Container(
                    width: 120,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      image: DecorationImage(
                        image: NetworkImage(image.urlSmall.isNotEmpty
                            ? image.urlSmall
                            : image.url),
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
          ],

          // AI Chat Button
          OutlinedButton.icon(
            icon: const Icon(Icons.chat_bubble_outline),
            label: const Text('Ask Plant AI Assistant'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.green,
              side: const BorderSide(color: Colors.green),
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Navigator.pushNamed(context, '/chat'),
          ),
        ],
      ),
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: const [
              Icon(Icons.sensors, color: Colors.green),
              SizedBox(width: 8),
              Text(
                "Live Sensor Overview",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Prediction Card
          if (_needsWater != null)
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              color: _needsWater! ? Colors.red[50] : Colors.green[50],
              child: ListTile(
                leading: Icon(
                  _needsWater! ? Icons.warning : Icons.check_circle,
                  color: _needsWater! ? Colors.red : Colors.green,
                ),
                title: Text(
                  _needsWater!
                      ? "🌱 Watering Needed"
                      : "✅ No Watering Required",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _needsWater! ? Colors.red : Colors.green,
                  ),
                ),
                subtitle: Text("Based on latest sensor readings"),
              ),
            ),

          const SizedBox(height: 20),

          // Temperature Sensor
          _buildSensorCard(
            label: "🌡️ Temperature",
            latest: latestTemperature,
            data: temperatureData,
            color: Colors.redAccent,
          ),
          const SizedBox(height: 24),

          // Humidity Sensor
          _buildSensorCard(
            label: "💧 Soil Humidity",
            latest: latestHumidity,
            data: soilHumidityData,
            color: Colors.blueAccent,
          ),
          const SizedBox(height: 24),

          // View History Button
          Center(
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => SensorHistoryPage(
                    temperatureData: temperatureData,
                    humidityData: soilHumidityData,
                  ),
                ));
              },
              icon: const Icon(Icons.history),
              label: const Text("View Full History"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),
          Center(
            child: Text(
              'Last Updated: $_lastUpdated',
              style: const TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
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
            Text(latest != null ? "Current: ${latest.toStringAsFixed(2)}" : ""),
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Watering Recommendation Card
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.water_drop,
                          color: Colors.blue,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Watering Guide',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (recommendedWateringDays != null &&
                      recommendedWateringAmount != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildWateringTipItem(
                          icon: Icons.calendar_today,
                          title: 'Frequency',
                          value:
                              'Every ${recommendedWateringDays!.toStringAsFixed(1)} days',
                        ),
                        _buildWateringTipItem(
                          icon: Icons.thermostat,
                          title: 'Amount',
                          value:
                              '${recommendedWateringAmount!.toStringAsFixed(0)} mm per watering',
                        ),
                        _buildWateringTipItem(
                          icon: Icons.notifications,
                          title: 'Next Watering',
                          value: _getNextWateringTime(),
                        ),
                      ],
                    )
                  else
                    const Text(
                      'Calculating watering recommendations...',
                      style: TextStyle(color: Colors.grey),
                    )
                ],
              ),
            ),
          ),

          // Notification Test Button
          Center(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.notifications_active, size: 20),
              label: const Text("Test Watering Reminder"),
              onPressed: () async {
                await scheduleWateringReminder(
                  DateTime.now().add(const Duration(seconds: 1)),
                  plantName: widget.plant.name,
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Test notification scheduled in 1 second'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Care Tips Section
          if (details != null) ...[
            const Text(
              'Plant Care Guide',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildCareTipCard(
              icon: Icons.light_mode,
              title: 'Light Requirements',
              content: details.bestLightCondition ?? 'Not specified',
              color: Colors.orange[50]!,
            ),
            _buildCareTipCard(
              icon: Icons.grass,
              title: 'Soil Preferences',
              content: details.bestSoilType ?? 'Not specified',
              color: Colors.brown[50]!,
            ),
            _buildCareTipCard(
              icon: Icons.opacity,
              title: 'Watering Tips',
              content: details.bestWatering ?? 'Not specified',
              color: Colors.blue[50]!,
            ),
            _buildCareTipCard(
              icon: Icons.eco,
              title: 'Common Uses',
              content: details.commonUses ?? 'Not specified',
              color: Colors.green[50]!,
            ),
          ] else
            const Center(
              child: Padding(
                padding: EdgeInsets.only(top: 40),
                child: Text(
                  'No care information available',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
        ],
      ),
    );
  }

  Widget _buildWateringTipItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.blue),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCareTipCard({
    required IconData icon,
    required String title,
    required String content,
    required Color color,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      color: color,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 20, color: Colors.grey[700]),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    content,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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
      height: 220,
      child: LineChart(
        LineChartData(
          minY: data.map((d) => (d['value'] as num).toDouble()).reduce(min) - 1,
          maxY: data.map((d) => (d['value'] as num).toDouble()).reduce(max) + 1,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: true,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Colors.grey.shade300,
              strokeWidth: 1,
            ),
            getDrawingVerticalLine: (value) => FlLine(
              color: Colors.grey.shade300,
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < data.length) {
                    return Text(data[index]['time'],
                        style: const TextStyle(fontSize: 10));
                  } else {
                    return const SizedBox.shrink();
                  }
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: true),
          lineBarsData: [
            LineChartBarData(
              spots: data
                  .asMap()
                  .entries
                  .map((e) => FlSpot(
                        e.key.toDouble(),
                        (e.value['value'] as num).toDouble(),
                      ))
                  .toList(),
              isCurved: true,
              color: lineColor,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: lineColor.withOpacity(0.2),
              ),
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
