import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_onboarding/ui/scan_page.dart';
import 'package:flutter_onboarding/ui/screens/detail_page.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_onboarding/models/plants.dart';
import 'package:cached_network_image/cached_network_image.dart';

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
    if (kIsWeb) {
      // 🧠 Important: For Web, 10.0.2.2 is NOT 10.0.2.2 — it must be your computer IP or a deployed server
      return 'http://127.0.0.1:5000'; // CHANGE if needed when you deploy
    } else {
      return 'http://10.0.2.2:5000'; // Android emulator uses 10.0.2.2 to reach 10.0.2.2
    }
  }

  @override
  void initState() {
    super.initState();
    fetchPlants();
  }

  Future<void> refreshPlants() async {
    await fetchPlants();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    fetchPlants();
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

        if (data.isEmpty) {
          print("No plants found.");
        }
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
    Size size = MediaQuery.of(context).size;

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ScanPage(userId: widget.userId),
            ),
          );

          if (result == true) {
            await fetchPlants();
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
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.only(left: 16, bottom: 20, top: 20),
              child: const Text(
                'New Plants',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18.0,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              height: size.height * 1,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : plantList.isEmpty
                      ? const Center(
                          child: Text(
                            'No Plant Found',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      : ListView.builder(
                          itemCount: plantList.length,
                          scrollDirection: Axis.vertical,
                          itemBuilder: (context, index) {
                            final plant = plantList[index];
                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        DetailPage(plant: plant),
                                  ),
                                );
                              },
                              child: Dismissible(
                                key: Key(plant.id),
                                onDismissed: (direction) {
                                  deletePlant(plant.id);
                                },
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
                                    onPressed: () {
                                      deletePlant(plant.id);
                                    },
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
