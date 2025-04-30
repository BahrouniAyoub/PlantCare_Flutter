const mongoose = require('mongoose');

// Define schema for Measurement
const MeasurementSchema = new mongoose.Schema({
  potId: {
    type: String,
    required: true
  },
  temperature: {
    type: Number,
    required: true
  },
  humidity: {
    type: Number,
    required: true
  },
  date: {
    type: Date,
    default: Date.now
  }
});

module.exports = mongoose.model('Measurement', MeasurementSchema);
