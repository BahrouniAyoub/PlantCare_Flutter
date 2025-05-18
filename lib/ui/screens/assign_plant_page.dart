import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_onboarding/models/plants.dart';

class AssignPlantPage extends StatefulWidget {
  final String userId;

  const AssignPlantPage({Key? key, required this.userId}) : super(key: key);

  @override
  _AssignPlantPageState createState() => _AssignPlantPageState();
}

class _AssignPlantPageState extends State<AssignPlantPage> {
  final List<String> pots = ['Pot A', 'Pot B', 'Pot C'];
  List<Plant> plantList = [];

  String? selectedPot;
  Plant? selectedPlant;

  bool isLoading = true;

  final String _backendUrl = 'http://192.168.1.10:5000';

  @override
  void initState() {
    super.initState();
    _fetchPlants();
  }

  Future<void> _fetchPlants() async {
    try {
      final response =
          await http.get(Uri.parse('$_backendUrl/plants/${widget.userId}'));

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        setState(() {
          plantList = data.map((p) => Plant.fromJson(p)).toList();
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load plants');
      }
    } catch (e) {
      print('Error fetching plants: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> _assignPlantToPot() async {
    if (selectedPot != null && selectedPlant != null) {
      final body = jsonEncode({
        'plantId': selectedPlant!.id,
        'potName': selectedPot!,
      });

      try {
        final response = await http.post(
          Uri.parse('$_backendUrl/plants/assign'),
          headers: {'Content-Type': 'application/json'},
          body: body,
        );

        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ ${selectedPlant!.name} assigned to $selectedPot'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          throw Exception('Failed to assign plant');
        }
      } catch (e) {
        print('Error assigning plant: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Error assigning plant to pot'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Please select both a pot and a plant.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assign Plant to Pot'),
        backgroundColor: Colors.green,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedPot,
                    hint: const Text('Select a Pot'),
                    items: pots
                        .map((pot) =>
                            DropdownMenuItem(value: pot, child: Text(pot)))
                        .toList(),
                    onChanged: (value) => setState(() => selectedPot = value),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12),
                    ),
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<Plant>(
                    value: selectedPlant,
                    hint: const Text('Select a Plant'),
                    items: plantList
                        .map((plant) => DropdownMenuItem(
                              value: plant,
                              child: Text(plant.name),
                            ))
                        .toList(),
                    onChanged: (value) => setState(() => selectedPlant = value),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12),
                    ),
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton.icon(
                    onPressed: _assignPlantToPot,
                    icon: const Icon(Icons.check),
                    label: const Text('Assign'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  )
                ],
              ),
            ),
    );
  }
}
