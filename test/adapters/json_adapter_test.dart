import 'package:mockito/mockito.dart';
import 'package:streaming_shared_preferences/streaming_shared_preferences.dart';
import 'package:test/test.dart';

import '../mocks.dart';

class TestObject {
  TestObject(this.hello);
  final String hello;

  TestObject.fromJson(Map<String, dynamic> json) : hello = json['hello'];

  Map<String, dynamic> toJson() {
    return {
      'hello': 'world',
    };
  }
}

void main() {
  group('ValueAdapter tests', () {
    MockSharedPreferences preferences;

    setUp(() {
      preferences = MockSharedPreferences();
    });

    group('JsonAdapter', () {
      test('fails gracefully when getting a null value', () {
        when(preferences.getString('key')).thenReturn(null);

        final adapter = JsonAdapter();
        final json = adapter.get(preferences, 'key');

        expect(json, isNull);
      });

      test('decodes a stored JSON value into a Map', () {
        when(preferences.getString('key')).thenReturn('{"hello":"world"}');

        final adapter = JsonAdapter();
        final json = adapter.get(preferences, 'key');

        expect(json, {'hello': 'world'});
      });

      test('decodes a stored JSON value into a List', () {
        when(preferences.getString('key')).thenReturn('["hello","world"]');

        final adapter = JsonAdapter();
        final json = adapter.get(preferences, 'key');

        expect(json, ['hello', 'world']);
      });

      test('stores an object that implements a toJson() method', () {
        final adapter = JsonAdapter<TestObject>();
        adapter.set(preferences, 'key', TestObject('world'));

        verify(preferences.setString('key', '{"hello":"world"}'));
      });

      test('runs decoded json through deserializer when provided', () {
        when(preferences.getString('key')).thenReturn('{"hello":"world"}');

        final adapter = JsonAdapter<TestObject>(
          deserializer: (v) => TestObject.fromJson(v),
        );

        final testObject = adapter.get(preferences, 'key');
        expect(testObject.hello, 'world');
      });

      test('runs object through serializer when provided', () {
        final adapter = JsonAdapter<TestObject>(
          serializer: (v) => {'encoded': 'value'},
        );

        // What value we set here doesn't matter - we're testing that it's replaced
        // by the value returned by serializer.
        adapter.set(preferences, 'key', null);
        verify(preferences.setString('key', '{"encoded":"value"}'));
      });
    });
  });
}
