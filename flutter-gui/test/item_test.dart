import 'package:flutter_test/flutter_test.dart';
import 'package:chatgpt_flutter_gui/main.dart';

void main() {
  test('item serialization', () {
    final item = Item(id: 1, prompt: 'p', response: 'r');
    final map = item.toJson();
    expect(map['id'], 1);
    final back = Item.fromJson(map);
    expect(back.prompt, 'p');
  });
}
