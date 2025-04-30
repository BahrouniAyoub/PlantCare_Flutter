const express = require('express');
const router = express.Router();
const plantController = require('../controllers/plantController');

// Route to add a new plant
router.post('/', plantController.addPlant);

// Route to get all plants for a user by userId
router.get('/:id', plantController.getPlants);

// Route to get a specific plant by its ID
router.get('/plant/:id', plantController.getPlantById);

// Route to update a plant by its ID
router.put('/:id', plantController.updatePlant);

// Route to delete a plant by its ID
router.delete('/:id', plantController.deletePlant);

module.exports = router;
