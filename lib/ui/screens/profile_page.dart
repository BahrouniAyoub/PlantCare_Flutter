import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_onboarding/constants.dart';
import 'package:flutter_onboarding/ui/screens/widgets/profile_widget.dart';
import 'package:flutter_onboarding/ui/screens/sensor_history_page.dart';
import 'package:flutter_onboarding/ui/screens/ChatWithLLMScreen .dart';
import 'package:http/http.dart' as http;

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  String name = 'Loading...';
  String email = 'Loading...';
  int totalPlants = 0;

  final String _backendUrl = 'http://192.168.1.10:5000';

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _fetchTotalPlants();
  }

  Future<void> _loadUserData() async {
    final storedName = await _storage.read(key: 'userName');
    final storedEmail = await _storage.read(key: 'userEmail');

    setState(() {
      name = storedName ?? 'Unknown';
      email = storedEmail ?? 'Unknown';
    });
  }

  Future<void> _fetchTotalPlants() async {
    final userId = await _storage.read(key: 'userId');
    print('Loaded userId: $userId');

    if (userId == null) return;

    try {
      final response = await http.get(Uri.parse('$_backendUrl/plants/$userId'));
      print('🔁 Status: ${response.statusCode}');
      print('📦 Body: ${response.body}');

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        setState(() {
          totalPlants = data.length;
        });
        print('🌱 Total plants found: ${data.length}');
      } else {
        print('❌ Failed to fetch plants. Status: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching total plants: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(16),
          height: size.height,
          width: size.width,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 150,
                child: const CircleAvatar(
                  radius: 60,
                  backgroundImage:
                      ExactAssetImage('assets/images/profile2.jpg'),
                ),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Constants.primaryColor.withOpacity(.5),
                    width: 5.0,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: size.width * .6,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        style: TextStyle(
                          color: Constants.blackColor,
                          fontSize: 20,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    SizedBox(
                      height: 24,
                      child: Image.asset("assets/images/verified.png"),
                    ),
                  ],
                ),
              ),
              Text(
                email,
                style: TextStyle(
                  color: Constants.blackColor.withOpacity(.3),
                ),
              ),
              const SizedBox(height: 30),
              Column(
                children: [
                  ProfileWidget(
                    icon: Icons.nature,
                    title: 'Total Plants Added: $totalPlants',
                    onTap: null, // Optional: navigate to plant list if needed
                  ),
                  ProfileWidget(
                    icon: Icons.chat,
                    title: 'Chat with AI',
                    onTap: () {
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => const ChatWithLLMScreen(),
                      ));
                    },
                  ),
                  ProfileWidget(
                    icon: Icons.history,
                    title: 'History',
                    onTap: () {
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => const SensorHistoryPage(
                          temperatureData: [],
                          humidityData: [],
                        ),
                      ));
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.logout, color: Colors.white),
                    label: const Text('Log Out'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                    onPressed: () {
                      Navigator.of(context)
                          .pushReplacementNamed('/signin_page');
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
