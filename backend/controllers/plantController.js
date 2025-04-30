// controllers/plantController.js
const Plant = require('../models/Plant');

// Add a new plant
exports.addPlant = async (req, res) => {
  try {
    // Destructure all required fields from req.body
    const {
      name,
      image,
      userId,
      is_plant,
      classification,
      plantHealth,
      status,
      sla_compliant_client,
      sla_compliant_system,
      created_datetime,
      finished_datetime,
    } = req.body;

    // Create a new Plant instance with all the provided data
    const plant = new Plant({
      name,
      image,
      userId,
      is_plant,
      classification,
      plantHealth,
      status,
      sla_compliant_client,
      sla_compliant_system,
      created_datetime,
      finished_datetime,
    });

    // Save the plant to the database
    await plant.save();

    // Send the saved plant as the response
    res.status(201).json(plant);
  } catch (error) {
    console.error('Add plant error:', error);
    res.status(500).send('Error adding plant');
  }
};

// Get all plants for a user
exports.getPlants = async (req, res) => {
  const { id } = req.params; // Extracting "id" instead of "userId"

  if (!id) {
    return res.status(400).json({ error: "User ID is required" });
  }

  try {
    const plants = await Plant.find({ userId: id }); // Using id as userId
    res.status(200).json(plants);
  } catch (error) {
    console.error("Get plants error:", error);
    res.status(500).send("Error fetching plants");
  }
};

// Get a plant by ID
exports.getPlantById = async (req, res) => {
  const { id } = req.params; // Extract the plant ID from the request parameters

  try {
    const plant = await Plant.findById(id); // Find the plant by its ID

    if (!plant) {
      return res.status(404).json({ error: 'Plant not found' }); // Return 404 if the plant doesn't exist
    }

    res.status(200).json(plant); // Return the plant data
  } catch (error) {
    console.error('Get plant by ID error:', error);
    res.status(500).send('Error fetching plant');
  }
};


// Update a plant
exports.updatePlant = async (req, res) => {
  const { id } = req.params;
  const { name, type, wateringFrequency, lastWatered, userId } = req.body;
  try {
    const plant = await Plant.findByIdAndUpdate(
      id,
      { name, type, wateringFrequency, lastWatered, userId },
      { new: true }
    );
    res.status(200).json(plant);
  } catch (error) {
    console.error('Update plant error:', error);
    res.status(500).send('Error updating plant');
  }
};

// Delete a plant
exports.deletePlant = async (req, res) => {
  const { id } = req.params;
  try {
    await Plant.findByIdAndDelete(id);
    res.status(200).send('Plant deleted');
  } catch (error) {
    console.error('Delete plant error:', error);
    res.status(500).send('Error deleting plant');
  }
};