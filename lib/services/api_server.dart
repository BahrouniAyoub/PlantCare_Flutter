import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiService {
  static Future<bool?> getWateringRecommendation({
    required double soilMoisture,
    required double temperature,
    required double soilHumidity,
    required double ph,
    required double rainfall,
    required double airHumidity,
  }) async {
    final url = Uri.parse('http://192.168.1.10:8000/predict');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "soil_moisture": soilMoisture,
          "temperature": temperature,
          "soil_humidity": soilHumidity,
          "ph": ph,
          "rainfall": rainfall,
          "air_humidity": airHumidity,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['needs_water'] == 1;
      } else {
        print("Prediction failed: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("Error calling prediction API: $e");
      return null;
    }
  }
}
