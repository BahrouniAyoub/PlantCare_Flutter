import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ChatWithLLMScreen extends StatefulWidget {
  const ChatWithLLMScreen({super.key});

  @override
  State<ChatWithLLMScreen> createState() => _ChatWithLLMScreenState();
}

class _ChatWithLLMScreenState extends State<ChatWithLLMScreen> {
  final TextEditingController _controller = TextEditingController();
  String? response;
  bool loading = false;

  Future<void> askOllama(String prompt) async {
    setState(() {
      loading = true;
      response = null;
    });

    const ollamaUrl = 'http://10.0.2.2:11434/api/generate'; // or 10.0.2.2 on Android emulator

    final body = jsonEncode({
      "model": "mistral", // or another model you have locally
      "prompt": prompt,
      "stream": false
    });

    try {
      final res = await http.post(
        Uri.parse(ollamaUrl),
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          response = data['response']?.toString().trim();
        });
      } else {
        setState(() {
          response = 'Failed to get response. Status: ${res.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        response = 'Error: $e';
      });
    }

    setState(() {
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Chat with Ollama")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: "Ask your plant care question...",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => askOllama(_controller.text),
              child: const Text("Ask Ollama"),
            ),
            const SizedBox(height: 20),
            if (loading)
              const CircularProgressIndicator()
            else if (response != null)
              Expanded(
                child: SingleChildScrollView(
                  child: Text(response!, style: const TextStyle(fontSize: 16)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
