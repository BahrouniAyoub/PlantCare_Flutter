// models/Plant.js
const mongoose = require('mongoose');

const PlantSchema = new mongoose.Schema({
  name: String,
  image: String,
  userId: String,
  is_plant: {
    probability: Number,
    binary: Boolean,
    threshold: Number,
  },
  classification: {
    suggestions: [
      {
        id: String,
        name: String,
        probability: Number,
        similar_images: [
          {
            id: String,
            url: String,
            license_name: String,
            license_url: String,
            citation: String,
            similarity: Number,
            url_small: String,
          },
        ],
        details: {
          language: String,
          entity_id: String,
          common_names: [String],
          description: {
            value: String,
            citation: String,
            license_name: String,
            license_url: String,
          },
          common_uses: String,
          best_light_condition: String,
          best_watering: String,
          best_soil_type: String,
          toxicity: String,
        },
      },
    ],
  },
  // Plant Health Field updated to accept nested objects
  plantHealth: {
    is_healthy: {
      probability: Number,
      binary: Boolean,
    },
    disease: {
      suggestions: [
        {
          name: String,
          probability: Number,
          details: {
            description: String,
            // Change treatment from String to Mixed:
            treatment: { type: mongoose.Schema.Types.Mixed },
            cause: String,
            url: String,
          },
        },
      ],
    },
  },
  status: String,
  sla_compliant_client: Boolean,
  sla_compliant_system: Boolean,
  created_datetime: Number,
  finished_datetime: Number,
});

module.exports = mongoose.model('Plant', PlantSchema);
