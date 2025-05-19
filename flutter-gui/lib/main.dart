import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(const MyApp());
}

class Item {
  final int id;
  final String prompt;
  final String response;

  Item({required this.id, required this.prompt, required this.response});

  Map<String, dynamic> toJson() => {
        'id': id,
        'prompt': prompt,
        'response': response,
      };

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      id: json['id'] as int,
      prompt: json['prompt'] as String,
      response: json['response'] as String,
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ChatGPT Flutter GUI',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const ChatPage(),
    );
  }
}

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _promptController = TextEditingController();
  final TextEditingController _apiKeyController = TextEditingController();
  List<Item> _items = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<File> get _dataFile async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/data.json');
  }

  Future<void> _loadItems() async {
    try {
      final file = await _dataFile;
      if (!await file.exists()) {
        setState(() => _items = []);
        return;
      }
      final jsonStr = await file.readAsString();
      if (jsonStr.isEmpty) {
        setState(() => _items = []);
        return;
      }
      final List list = json.decode(jsonStr);
      setState(() => _items = list.map((e) => Item.fromJson(e)).toList());
    } catch (e) {
      // ignore errors on load
    }
  }

  Future<void> _saveItems() async {
    final file = await _dataFile;
    final jsonStr = json.encode(_items.map((e) => e.toJson()).toList());
    await file.writeAsString(jsonStr);
  }

  Future<void> _createItem(String prompt) async {
    final apiKey = _apiKeyController.text.trim();
    if (apiKey.isEmpty) return;
    setState(() => _loading = true);
    try {
      final responseText = await _callOpenAI(prompt, apiKey);
      final id = _items.isEmpty ? 1 : _items.last.id + 1;
      final item = Item(id: id, prompt: prompt, response: responseText);
      setState(() => _items.add(item));
      await _saveItems();
      _promptController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<String> _callOpenAI(String prompt, String apiKey) async {
    final uri = Uri.parse('https://api.openai.com/v1/chat/completions');
    final body = json.encode({
      'model': 'gpt-4o',
      'messages': [
        {'role': 'user', 'content': prompt}
      ]
    });
    final resp = await http.post(uri,
        headers: {
          HttpHeaders.authorizationHeader: 'Bearer $apiKey',
          HttpHeaders.contentTypeHeader: 'application/json'
        },
        body: body);
    if (resp.statusCode != 200) {
      throw Exception('API error: ${resp.body}');
    }
    final parsed = json.decode(resp.body);
    final choices = parsed['choices'] as List?;
    if (choices == null || choices.isEmpty) {
      throw Exception('No choices returned');
    }
    return choices[0]['message']['content'] as String;
  }

  Future<void> _deleteItem(int id) async {
    setState(() => _items.removeWhere((it) => it.id == id));
    await _saveItems();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ChatGPT Flutter GUI')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _apiKeyController,
              decoration: const InputDecoration(labelText: 'OpenAI API Key'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _promptController,
              decoration: const InputDecoration(labelText: 'Prompt'),
              onSubmitted: (value) {
                if (!_loading) {
                  _createItem(value);
                }
              },
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed:
                  _loading ? null : () => _createItem(_promptController.text),
              child: _loading
                  ? const CircularProgressIndicator()
                  : const Text('Send'),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _items.length,
                itemBuilder: (context, index) {
                  final item = _items[index];
                  return ListTile(
                    title: Text(item.prompt),
                    subtitle: Text(item.response),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _deleteItem(item.id),
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
