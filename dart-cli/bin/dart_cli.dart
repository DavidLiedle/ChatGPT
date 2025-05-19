import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:http/http.dart' as http;

class Item {
  int id;
  String prompt;
  String response;

  Item({required this.id, required this.prompt, required this.response});

  factory Item.fromJson(Map<String, dynamic> json) =>
      Item(id: json['id'], prompt: json['prompt'], response: json['response']);

  Map<String, dynamic> toJson() =>
      {'id': id, 'prompt': prompt, 'response': response};
}

const String dataFile = 'data.json';

Future<List<Item>> loadItems() async {
  final file = File(dataFile);
  if (!await file.exists()) return [];
  final contents = await file.readAsString();
  if (contents.trim().isEmpty) return [];
  final data = json.decode(contents) as List<dynamic>;
  return data.map((e) => Item.fromJson(e as Map<String, dynamic>)).toList();
}

Future<void> saveItems(List<Item> items) async {
  final file = File(dataFile);
  await file.writeAsString(json.encode(items), flush: true);
}

Future<String> callOpenAI(String prompt, String apiKey) async {
  final body = json.encode({
    'model': 'gpt-4o',
    'messages': [
      {'role': 'user', 'content': prompt}
    ]
  });
  final response = await http.post(
    Uri.parse('https://api.openai.com/v1/chat/completions'),
    headers: {
      'Authorization': 'Bearer $apiKey',
      'Content-Type': 'application/json',
    },
    body: body,
  );
  if (response.statusCode != 200) {
    throw Exception('API error: ${response.body}');
  }
  final parsed = json.decode(response.body) as Map<String, dynamic>;
  final choices = parsed['choices'] as List<dynamic>;
  if (choices.isEmpty) {
    throw Exception('No choices returned');
  }
  return choices.first['message']['content'] as String;
}

Future<Item> createItem(String prompt, List<Item> items, String apiKey) async {
  final response = await callOpenAI(prompt, apiKey);
  final id = items.isNotEmpty ? items.last.id + 1 : 1;
  final item = Item(id: id, prompt: prompt, response: response);
  items.add(item);
  return item;
}

Future<Item> updateItem(
    int id, String prompt, List<Item> items, String apiKey) async {
  final index = items.indexWhere((e) => e.id == id);
  if (index == -1) throw Exception('item $id not found');
  final response = await callOpenAI(prompt, apiKey);
  items[index].prompt = prompt;
  items[index].response = response;
  return items[index];
}

void deleteItem(int id, List<Item> items) {
  final index = items.indexWhere((e) => e.id == id);
  if (index == -1) throw Exception('item $id not found');
  items.removeAt(index);
}

void listItems(List<Item> items) {
  for (var it in items) {
    stdout.writeln('${it.id}: ${it.prompt} -> ${it.response}');
  }
}

void printUsage(ArgParser parser) {
  stdout.writeln('Usage: dart_cli.dart [options]');
  stdout.writeln(parser.usage);
}

Future<void> main(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption('create', abbr: 'c', help: 'Create a new item with PROMPT')
    ..addOption('update', abbr: 'u', help: 'Update item ID with PROMPT')
    ..addOption('delete', abbr: 'd', help: 'Delete item with ID')
    ..addFlag('list', abbr: 'l', negatable: false, help: 'List all items')
    ..addFlag('help', abbr: 'h', negatable: false, help: 'Show this help');

  ArgResults argResults;
  try {
    argResults = parser.parse(arguments);
  } on FormatException catch (e) {
    stderr.writeln(e.message);
    printUsage(parser);
    exit(64);
  }

  if (argResults['help'] as bool) {
    printUsage(parser);
    return;
  }

  final apiKey = Platform.environment['OPENAI_API_KEY'];
  if (apiKey == null || apiKey.isEmpty) {
    stderr.writeln('OPENAI_API_KEY not set');
    exit(1);
  }

  final items = await loadItems();

  try {
    if (argResults.wasParsed('create')) {
      final prompt = argResults['create'] as String?;
      if (prompt == null || prompt.isEmpty) {
        stderr.writeln('Missing prompt for --create');
        exit(64);
      }
      final item = await createItem(prompt, items, apiKey);
      await saveItems(items);
      stdout.writeln('Created item ${item.id}');
    } else if (argResults.wasParsed('update')) {
      final value = argResults['update'] as String?;
      if (value == null || value.isEmpty) {
        stderr.writeln('Missing "ID:PROMPT" for --update');
        exit(64);
      }
      final parts = value.split(':');
      if (parts.length != 2) {
        stderr.writeln('Use --update ID:PROMPT');
        exit(64);
      }
      final id = int.tryParse(parts[0]);
      if (id == null) {
        stderr.writeln('Invalid ID for --update');
        exit(64);
      }
      final prompt = parts[1];
      final item = await updateItem(id, prompt, items, apiKey);
      await saveItems(items);
      stdout.writeln('Updated item ${item.id}');
    } else if (argResults.wasParsed('delete')) {
      final idStr = argResults['delete'] as String?;
      if (idStr == null || idStr.isEmpty) {
        stderr.writeln('Missing ID for --delete');
        exit(64);
      }
      final id = int.tryParse(idStr);
      if (id == null) {
        stderr.writeln('Invalid ID for --delete');
        exit(64);
      }
      deleteItem(id, items);
      await saveItems(items);
      stdout.writeln('Deleted item $id');
    } else if (argResults['list'] as bool) {
      listItems(items);
    } else {
      printUsage(parser);
    }
  } on Exception catch (e) {
    stderr.writeln('Error: $e');
    exit(1);
  }
}
