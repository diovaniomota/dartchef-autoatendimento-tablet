import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:next_food_tablet_app/src/services/update_service.dart';

void main() {
  test('0.2.19 e mais nova que 0.2.14', () {
    expect(versaoEhMaisNova('0.2.19', '0.2.14'), isTrue);
    expect(versaoEhMaisNova('0.2.14', '0.2.19'), isFalse);
    expect(versaoEhMaisNova('0.2.14', '0.2.14'), isFalse);
  });

  test('APK comeca com PK; HTML do GitHub nao passa', () {
    expect(arquivoPareceApk(Uint8List.fromList([0x50, 0x4b, 0x03, 0x04])), isTrue);
    expect(arquivoPareceApk(Uint8List.fromList('<html>'.codeUnits)), isFalse);
    expect(arquivoPareceApk(Uint8List.fromList([0x50])), isFalse);
  });
}
