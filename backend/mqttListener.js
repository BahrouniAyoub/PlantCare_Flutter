// mqttListener.js
const mqtt = require('mqtt');
const mongoose = require('mongoose');
const SensorData = require('./models/SensorData');

mongoose.connect('mongodb://localhost:27017/plant_monitor');
const client = mqtt.connect('mqtts://15c46f3c33c749b9aeb58eef43d6369d.s1.eu.hivemq.cloud', {
  port: 8883,
  username: 'ayoub',
  password: 'Ayoub0303',
});

client.on('connect', () => {
  console.log('MQTT connected');
  client.subscribe('sensor/+/temp');
  client.subscribe('sensor/+/hum');
});

client.on('message', async (topic, message) => {
  const [_, plantId, type] = topic.split('/');
  const value = parseFloat(message.toString());

  if (!isNaN(value)) {
    await SensorData.create({ plantId, sensorType: type, value });
    console.log(`Saved ${type} for ${plantId}: ${value}`);
  }
});
