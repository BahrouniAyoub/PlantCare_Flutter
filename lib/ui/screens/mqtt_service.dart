// import 'package:mqtt_client/mqtt_client.dart';
// import 'package:mqtt_client/mqtt_browser_client.dart';
// import 'package:mqtt_client/mqtt_server_client.dart';
// import 'package:flutter/foundation.dart' show kIsWeb;

// class MqttService {
//   late MqttClient client;
//   final Function(String, String) onMessageReceived;

//   MqttService({required this.onMessageReceived});

//   Future<void> connect() async {
//     if (kIsWeb) {
//       client = MqttBrowserClient(
//         'wss://15c46f3c33c749b9aeb58eef43d6369d.s1.eu.hivemq.cloud:8884/mqtt', 
//         'flutter_web_client'
//       );
//     } else {
//       client = MqttServerClient.withPort(
//         '15c46f3c33c749b9aeb58eef43d6369d.s1.eu.hivemq.cloud',
//         'flutter_mobile_client',
//         8883,
//       );
//       (client as MqttServerClient).secure = true;
//     }

//     client.logging(on: false);
//     client.keepAlivePeriod = 20;
//     client.onDisconnected = _onDisconnected;
//     client.onConnected = _onConnected;
//     client.onSubscribed = _onSubscribed;

//     final connMessage = MqttConnectMessage()
//         .authenticateAs('ayoub', 'Ayoub0303')
//         .withClientIdentifier('flutter_client')
//         .startClean();
//     client.connectionMessage = connMessage;

//     try {
//       await client.connect();
//     } catch (e) {
//       print('MQTT connection failed: $e');
//       client.disconnect();
//     }

//     client.updates?.listen((List<MqttReceivedMessage<MqttMessage>> c) {
//       final recMess = c[0].payload as MqttPublishMessage;
//       final payload = MqttPublishPayload.bytesToStringAsString(recMess.payload.message);

//       final topic = c[0].topic;
//       onMessageReceived(topic, payload);
//     });

//     client.subscribe('sensor/temperature', MqttQos.atMostOnce);
//     client.subscribe('sensor/humidity', MqttQos.atMostOnce);
//   }

//   void _onDisconnected() => print('MQTT Disconnected');
//   void _onConnected() => print('MQTT Connected');
//   void _onSubscribed(String topic) => print('Subscribed to $topic');

//   void disconnect() {
//     client.disconnect();
//   }
// }
