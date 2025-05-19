import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class Message {
  String role;
  String content;
  Message({required this.role, required this.content});

  factory Message.fromJson(Map<String, dynamic> json) =>
      Message(role: json['role'], content: json['content']);

  Map<String, dynamic> toJson() => {'role': role, 'content': content};
}

const String historyFile = 'history.json';

Future<List<Message>> loadHistory() async {
  final file = File(historyFile);
  if (!await file.exists()) return [];
  final contents = await file.readAsString();
  if (contents.trim().isEmpty) return [];
  final data = json.decode(contents) as List<dynamic>;
  return data.map((e) => Message.fromJson(e as Map<String, dynamic>)).toList();
}

Future<void> saveHistory(List<Message> messages) async {
  final file = File(historyFile);
  await file.writeAsString(json.encode(messages), flush: true);
}

Future<String> callOpenAI(List<Message> messages, String apiKey) async {
  final body = json.encode({'model': 'gpt-4o', 'messages': messages});
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

Future<void> chat(String apiKey) async {
  var history = await loadHistory();
  stdout.writeln("Enter 'exit' to quit.");
  while (true) {
    stdout.write('> ');
    final line = stdin.readLineSync();
    if (line == null) break;
    final text = line.trim();
    if (text == 'exit' || text == 'quit') break;
    history.add(Message(role: 'user', content: text));
    final reply = await callOpenAI(history, apiKey);
    stdout.writeln(reply);
    history.add(Message(role: 'assistant', content: reply));
    await saveHistory(history);
  }
}

Future<void> printHistory() async {
  final history = await loadHistory();
  for (final m in history) {
    stdout.writeln('${m.role}: ${m.content}');
  }
}

Future<void> clearHistory() async {
  final file = File(historyFile);
  if (await file.exists()) await file.delete();
}

Future<void> main(List<String> arguments) async {
  if (arguments.isEmpty) {
    stdout.writeln('Usage: [chat|history|clear]');
    return;
  }
  final apiKey = Platform.environment['OPENAI_API_KEY'];
  if (apiKey == null || apiKey.isEmpty) {
    stderr.writeln('OPENAI_API_KEY not set');
    exit(1);
  }
  switch (arguments.first) {
    case 'chat':
      await chat(apiKey);
      break;
    case 'history':
      await printHistory();
      break;
    case 'clear':
      await clearHistory();
      break;
    default:
      stdout.writeln('Unknown command');
  }
}
