import 'dart:convert';
import 'dart:typed_data'; // ✅ instead of dart:io
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class ScanPage extends StatefulWidget {
  final String userId;

  const ScanPage({Key? key, required this.userId}) : super(key: key);

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  final ImagePicker _picker = ImagePicker();
  XFile? _capturedImage;
  Uint8List? _capturedImageBytes; // ✅ Store image bytes
  bool _isLoading = false;

  static const String plantIdApiKey =
      'VTSXEXvv5uzUkTJULkgDFNmzDNJ5q2rlWJVzyXbMDa2FwaT0w7';

  String get _databaseUrl {
    if (kIsWeb) {
      return 'http://127.0.0.1:5000/plants'; // Web browser calls 10.0.2.2
    } else {
      return 'http://10.0.2.2:5000/plants'; // Android emulator 10.0.2.2
    }
  }

  Future<void> _openCamera() async {
    setState(() => _isLoading = true);

    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (photo != null) {
        final bytes = await photo.readAsBytes();
        setState(() {
          _capturedImage = photo;
          _capturedImageBytes = bytes;
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Plant scanned successfully')),
        );
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Error: ${e.toString()}');
    }
  }

  Future<void> _identifyPlant() async {
    if (_capturedImageBytes == null) return;

    setState(() => _isLoading = true);

    try {
      final base64Image = base64Encode(_capturedImageBytes!);

      final identificationUrl = Uri.parse(
          'https://api.plant.id/v3/identification?details=common_names,url,description,taxonomy,rank,gbif_id,inaturalist_id,image,synonyms,edible_parts,watering,propagation_methods,best_light_condition,best_soil_type,common_uses,best_watering&language=en');

      final identificationResponse = await http.post(
        identificationUrl,
        headers: {
          'Content-Type': 'application/json',
          'Api-Key': plantIdApiKey,
        },
        body: jsonEncode({
          "images": ["data:image/jpeg;base64,$base64Image"],
          "similar_images": true,
        }),
      );

      if (identificationResponse.statusCode != 200 &&
          identificationResponse.statusCode != 201) {
        _showError(
            'Plant identification failed. Status: ${identificationResponse.statusCode}');
        setState(() => _isLoading = false);
        return;
      }

      final Map<String, dynamic> identificationData =
          jsonDecode(identificationResponse.body);
      final result = identificationData['result'];
      final classification = result['classification'];
      final isPlant = result['is_plant'];

      final suggestions = classification['suggestions'] as List<dynamic>;
      if (suggestions.isEmpty) {
        _showError('No plant suggestions found.');
        setState(() => _isLoading = false);
        return;
      }

      final suggestion = suggestions[0];
      final plantName = suggestion['name'];

      // HEALTH check
      final healthUrl = Uri.parse(
          'https://plant.id/api/v3/health_assessment?details=local_name,description,url,treatment,classification,common_names,cause');

      final healthResponse = await http.post(
        healthUrl,
        headers: {
          'Content-Type': 'application/json',
          'Api-Key': plantIdApiKey,
        },
        body: jsonEncode({
          "images": ["data:image/jpeg;base64,$base64Image"],
        }),
      );

      Map<String, dynamic>? plantHealthData;
      if (healthResponse.statusCode == 200 ||
          healthResponse.statusCode == 201) {
        plantHealthData = jsonDecode(healthResponse.body)['result'];
      }

      // SAVE to database
      await _savePlantToDatabase(
        name: plantName,
        imageBase64: base64Image,
        userId: widget.userId,
        isPlant: isPlant,
        classification: {
          "suggestions": suggestions.map((s) {
            final Map<String, dynamic> suggestion =
                Map<String, dynamic>.from(s);
            suggestion['similar_images'] = suggestion['similar_images'] ?? [];
            return suggestion;
          }).toList(),
        },
        plantHealth: plantHealthData,
        status: "identified",
        slaCompliantClient: true,
        slaCompliantSystem: true,
        createdDateTime: DateTime.now().millisecondsSinceEpoch,
        finishedDateTime: DateTime.now().millisecondsSinceEpoch,
      );

      Navigator.pop(context, true);
    } catch (e) {
      _showError('Error: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _savePlantToDatabase({
    required String name,
    required String imageBase64,
    required String userId,
    required Map<String, dynamic> isPlant,
    required Map<String, dynamic> classification,
    required Map<String, dynamic>? plantHealth,
    required String status,
    required bool slaCompliantClient,
    required bool slaCompliantSystem,
    required int createdDateTime,
    required int finishedDateTime,
  }) async {
    final dbUrl = Uri.parse(_databaseUrl);

    try {
      final response = await http.post(
        dbUrl,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "name": name,
          "image": "data:image/jpeg;base64,$imageBase64",
          "userId": userId,
          "is_plant": isPlant,
          "classification": classification,
          "plantHealth": plantHealth,
          "status": status,
          "sla_compliant_client": slaCompliantClient,
          "sla_compliant_system": slaCompliantSystem,
          "created_datetime": createdDateTime,
          "finished_datetime": finishedDateTime,
        }),
      );

      if (response.statusCode == 201) {
        _showSuccess('Plant saved successfully!');
      } else {
        _showError('Failed to save plant: ${response.reasonPhrase}');
      }
    } catch (e) {
      _showError('Exception while saving: ${e.toString()}');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Plant'),
        centerTitle: true,
        actions: [
          if (_capturedImage != null)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => setState(() {
                _capturedImage = null;
                _capturedImageBytes = null;
              }),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _capturedImageBytes != null
              ? _buildImagePreview()
              : _buildCameraPrompt(),
      floatingActionButton: _capturedImageBytes != null
          ? FloatingActionButton.extended(
              onPressed: _openCamera,
              icon: const Icon(Icons.camera),
              label: const Text('Scan Again'),
            )
          : null,
    );
  }

  Widget _buildCameraPrompt() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.camera_alt, size: 100, color: Colors.green),
          const SizedBox(height: 20),
          const Text('Scan your plant', style: TextStyle(fontSize: 20)),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: _openCamera,
            icon: const Icon(Icons.camera),
            label: const Text('Open Camera'),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: kIsWeb
              ? Image.memory(_capturedImageBytes!, fit: BoxFit.cover)
              : Image.memory(_capturedImageBytes!, fit: BoxFit.cover),
        ),
      ),
    );
  }
}
