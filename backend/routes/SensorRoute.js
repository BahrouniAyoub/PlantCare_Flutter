// routes/sensorRoutes.js
const express = require('express');
const router = express.Router();
const SensorData = require('../models/SensorData');


router.post('/save', async (req, res) => {
    try {
        const { plantId, sensorType, value, timestamp } = req.body;
        const saved = await SensorData.create({ plantId, sensorType, value, timestamp });
        res.status(201).json(saved);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});


// GET /api/history/:plantId
router.get('/history/:plantId', async (req, res) => {
    try {
        const { plantId } = req.params;
        const since = req.query.since ? new Date(req.query.since) : null;

        const query = { plantId };
        if (since && !isNaN(since.getTime())) {
            query.timestamp = { $gte: since };
        }

        const history = await SensorData.find(query).sort({ timestamp: 1 });

        res.json(history);
    } catch (err) {
        console.error('Error fetching history:', err);
        res.status(500).json({ error: 'Server error' });
    }
});

module.exports = router;
