import 'dart:io';
import 'package:test/test.dart';
import '../bin/dart_cli.dart';

void main() {
  group('history', () {
    test('save and load', () async {
      final dir = Directory.systemTemp.createTempSync();
      final prev = Directory.current;
      Directory.current = dir;

      final messages = [Message(role: 'user', content: 'p')];
      await saveHistory(messages);
      final loaded = await loadHistory();
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

      Directory.current = prev;
    });

    test('load missing and empty', () async {
      final dir = Directory.systemTemp.createTempSync();
      final prev = Directory.current;
      Directory.current = dir;

      var msgs = await loadHistory();
      expect(msgs, isEmpty);

      File(historyFile).writeAsStringSync('');
      msgs = await loadHistory();
      expect(msgs, isEmpty);

      Directory.current = prev;
    });
  });
}
