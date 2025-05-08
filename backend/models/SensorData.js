// models/SensorData.js
const mongoose = require('mongoose');

const sensorDataSchema = new mongoose.Schema({
  plantId: String,
  sensorType: String, // 'temp' or 'hum'
  value: Number,
  timestamp: {
    type: Date,
    default: Date.now
  }
});

module.exports = mongoose.model('SensorData', sensorDataSchema);
