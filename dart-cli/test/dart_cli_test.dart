import 'dart:io';
import 'package:test/test.dart';
import '../bin/dart_cli.dart';

void main() {
  group('history', () {
    test('save and load', () async {
      var dir = Directory.systemTemp.createTempSync();
      var prev = Directory.current;
      Directory.current = dir;
      var messages = [Message(role: 'user', content: 'p')];
      await saveHistory(messages);
      var loaded = await loadHistory();
      expect(loaded.length, 1);
      expect(loaded.first.content, 'p');
      Directory.current = prev;
    });

    test('clear history', () async {

      final dir = Directory.systemTemp.createTempSync();
      final prev = Directory.current;
      Directory.current = dir;

      final msgs = [Message(role: 'user', content: 'bye')];
      await saveHistory(msgs);
      await clearHistory();
      expect(File(historyFile).existsSync(), isFalse);
      var dir = Directory.systemTemp.createTempSync();
      var prev = Directory.current;
      Directory.current = dir;
      var messages = [Message(role: 'user', content: 'bye')];
      await saveHistory(messages);
      await clearHistory();
      expect(File(historyFile).existsSync(), isFalse);
      Directory.current = prev;
    });
  });
}
