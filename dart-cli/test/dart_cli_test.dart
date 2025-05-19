import 'dart:io';
import 'package:test/test.dart';
import '../bin/dart_cli.dart';

void main() {
  group('storage', () {
    test('save and load', () async {
      var dir = Directory.systemTemp.createTempSync();
      var prev = Directory.current;
      Directory.current = dir;
      var items = [Item(id: 1, prompt: 'p', response: 'r')];
      await saveItems(items);
      var loaded = await loadItems();
      expect(loaded.length, 1);
      expect(loaded.first.prompt, 'p');
      Directory.current = prev;
    });

    test('delete item', () {
      var items = [
        Item(id: 1, prompt: 'a', response: 'b'),
        Item(id: 2, prompt: 'c', response: 'd')
      ];
      deleteItem(1, items);
      expect(items.length, 1);
      expect(items.first.id, 2);
      expect(() => deleteItem(3, items), throwsException);
    });
  });
}
