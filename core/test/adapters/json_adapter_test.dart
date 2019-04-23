import 'package:mockito/mockito.dart';
import 'package:streaming_key_value_store/streaming_key_value_store.dart';
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
    MockKeyValueStore keyValueStore;

    setUp(() {
      keyValueStore = MockKeyValueStore();
    });

    group('JsonAdapter', () {
      test('fails gracefully when getting a null value', () {
        when(keyValueStore.getString('key')).thenReturn(null);

        final adapter = JsonAdapter();
        final json = adapter.get(keyValueStore, 'key');

        expect(json, isNull);
      });

      test('decodes a stored JSON value into a Map', () {
        when(keyValueStore.getString('key')).thenReturn('{"hello":"world"}');

        final adapter = JsonAdapter();
        final json = adapter.get(keyValueStore, 'key');

        expect(json, {'hello': 'world'});
      });

      test('decodes a stored JSON value into a List', () {
        when(keyValueStore.getString('key')).thenReturn('["hello","world"]');

        final adapter = JsonAdapter();
        final json = adapter.get(keyValueStore, 'key');

        expect(json, ['hello', 'world']);
      });

      test('stores an object that implements a toJson() method', () {
        final adapter = JsonAdapter<TestObject>();
        adapter.set(keyValueStore, 'key', TestObject('world'));

        verify(keyValueStore.setString('key', '{"hello":"world"}'));
      });

      test('runs decoded json through deserializer when provided', () {
        when(keyValueStore.getString('key')).thenReturn('{"hello":"world"}');

        final adapter = JsonAdapter<TestObject>(
          deserializer: (v) => TestObject.fromJson(v),
        );

        final testObject = adapter.get(keyValueStore, 'key');
        expect(testObject.hello, 'world');
      });

      test('runs object through serializer when provided', () {
        final adapter = JsonAdapter<TestObject>(
          serializer: (v) => {'encoded': 'value'},
        );

        // What value we set here doesn't matter - we're testing that it's replaced
        // by the value returned by serializer.
        adapter.set(keyValueStore, 'key', null);
        verify(keyValueStore.setString('key', '{"encoded":"value"}'));
      });
    });
  });
}
