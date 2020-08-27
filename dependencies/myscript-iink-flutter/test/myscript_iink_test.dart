import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myscript_iink/myscript_iink.dart';

void main() {
  const MethodChannel channel = MethodChannel('myscript_iink');

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('getPlatformVersion', () async {
//    expect(await MyscriptIink.platformVersion, '42');
  });
}
