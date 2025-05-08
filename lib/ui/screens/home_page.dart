import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_onboarding/ui/scan_page.dart';
import 'package:flutter_onboarding/ui/screens/detail_page.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_onboarding/models/plants.dart';

class HomePage extends StatefulWidget {
  final String userId;

  const HomePage({Key? key, required this.userId}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Plant> plantList = [];
  bool _isLoading = true;

  String get _backendUrl {
    return 'http://10.0.2.2:5000'; // Replace with your backend IP
  }

  @override
  void initState() {
    super.initState();
    fetchPlants();
  }

  Future<void> refreshPlants() async {
    setState(() => _isLoading = true);
    await fetchPlants();
  }

  Future<void> fetchPlants() async {
    try {
      final response =
          await http.get(Uri.parse('$_backendUrl/plants/${widget.userId}'));

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);

        setState(() {
          plantList = data.map((plantData) {
            return Plant.fromJson(plantData);
          }).toList();
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load plants');
      }
    } catch (e) {
      print('Error fetching plants: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> deletePlant(String plantId) async {
    final response =
        await http.delete(Uri.parse('$_backendUrl/plants/$plantId'));

    if (response.statusCode == 200) {
      setState(() {
        plantList.removeWhere((plant) => plant.id == plantId);
      });
    } else {
      throw Exception('Failed to delete plant');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Plants'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: refreshPlants,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ScanPage(userId: widget.userId),
            ),
          );

          if (result == true) {
            await refreshPlants();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('New plant added!'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          }
        },
        child: const Icon(Icons.camera_alt),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : plantList.isEmpty
              ? const Center(
                  child: Text(
                    'No Plant Found',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: plantList.length,
                  itemBuilder: (context, index) {
                    final plant = plantList[index];
                    return Dismissible(
                      key: Key(plant.id),
                      direction: DismissDirection.endToStart,
                      onDismissed: (_) => deletePlant(plant.id),
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(8),
                        leading: Image.memory(
                          base64Decode(plant.image.split(',').last),
                          height: 80,
                          width: 80,
                          fit: BoxFit.cover,
                        ),
                        title: Text(plant.name),
                        subtitle: Text(plant.status),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => deletePlant(plant.id),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DetailPage(plant: plant),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
