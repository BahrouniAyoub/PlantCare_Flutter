import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class MqttService {
  final Function(String, String) onMessageReceived;
  late MqttServerClient client;
  final String plantId;

  MqttService({required this.onMessageReceived, required this.plantId});

  Future<void> connect() async {
    client = MqttServerClient.withPort(
        '15c46f3c33c749b9aeb58eef43d6369d.s1.eu.hivemq.cloud',
        'flutter_client',
        8883);

    client.secure = true;
    client.keepAlivePeriod = 20;
    client.logging(on: false);

    client.onConnected = () {
      print('MQTT Connected');
      client.subscribe('sensor/$plantId/temp', MqttQos.atMostOnce);
      client.subscribe('sensor/$plantId/hum', MqttQos.atMostOnce);
    };

    client.onDisconnected = () => print('MQTT Disconnected');
    client.onSubscribed = (topic) => print('Subscribed to $topic');

    client.connectionMessage = MqttConnectMessage()
        .authenticateAs('ayoub', 'Ayoub0303')
        .withClientIdentifier('flutter_client')
        .startClean();

    try {
      await client.connect();

      client.updates!.listen((List<MqttReceivedMessage<MqttMessage>> messages) {
        final recMess = messages[0].payload as MqttPublishMessage;
        final payload =
            MqttPublishPayload.bytesToStringAsString(recMess.payload.message);

        final topic = messages[0].topic;
        onMessageReceived(topic, payload);

        _saveSensorDataToBackend(topic, payload); // NEW: Save to DB
      });
    } catch (e) {
      print('MQTT Connection failed: $e');
      client.disconnect();
    }
  }

  void disconnect() {
    client.disconnect();
  }

  Future<void> _saveSensorDataToBackend(String topic, String valueStr) async {
    final sensorType = topic.endsWith('temp')
        ? 'temp'
        : topic.endsWith('hum')
            ? 'hum'
            : null;

    if (sensorType == null) return;

    final value = double.tryParse(valueStr);
    if (value == null) return;

    final timestamp = DateTime.now().toIso8601String();

    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:5000/api/save'), // Replace this
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'plantId': plantId,
          'sensorType': sensorType,
          'value': value,
          'timestamp': timestamp,
        }),
      );

      if (response.statusCode != 201) {
        print('❌ Failed to save to DB: ${response.body}');
      } else {
        print('✅ Sensor data saved: $sensorType = $value');
      }
    } catch (e) {
      print('❌ Error saving to backend: $e');
    }
  }
}
