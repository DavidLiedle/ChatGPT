import 'dart:io';
import 'package:test/test.dart';
import '../bin/dart_cli.dart';

void main() {
  group('storage', () {
    test('save and load history', () async {
      final dir = Directory.systemTemp.createTempSync();
      final prev = Directory.current;
      Directory.current = dir;

      final msgs = [Message(role: 'user', content: 'hello')];
      await saveHistory(msgs);
      final loaded = await loadHistory();
      expect(loaded.length, 1);
      expect(loaded.first.role, 'user');
      expect(loaded.first.content, 'hello');

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
  });
}
