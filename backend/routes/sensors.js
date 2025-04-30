const express = require('express');
const router = express.Router();
const Measurement = require('../models/Measurement');

// POST request to save sensor data
router.post('/', async (req, res) => {
  try {
    const { potId, temperature, humidity } = req.body;

    // Save the data in the new model (directly using temperature and humidity fields)
    const newMeasurement = new Measurement({
      potId,
      temperature,
      humidity,
    });

    await newMeasurement.save(); // Save the new measurement
    res.sendStatus(201); // Send success response
  } catch (err) {
    console.error(err);
    res.status(500).send('Erreur serveur'); // Error handling
  }
});

// GET request to fetch sensor data for a specific pot
router.get('/:potId', async (req, res) => {
  try {
    // Find the measurements related to the potId, and sort by date in descending order
    const data = await Measurement.find({ potId: req.params.potId })
      .sort('-date')  // Sort data by date (most recent first)
      .limit(100);    // Limit the results to the last 100 measurements

    res.json(data); // Return the data as JSON
  } catch (err) {
    console.error(err);
    res.status(500).send('Erreur serveur'); // Error handling
  }
});

module.exports = router;
