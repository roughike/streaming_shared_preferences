import 'package:mockito/mockito.dart';
import 'package:streaming_key_value_store/streaming_key_value_store.dart';
import 'package:test/test.dart';

import '../mocks.dart';

void main() {
  group('DateTimeAdapter', () {
    MockKeyValueStore keyValueStore;

    setUp(() {
      keyValueStore = MockKeyValueStore();
    });

    final adapter = DateTimeAdapter();
    final dateTime = DateTime(2019, 01, 02, 03, 04, 05, 99).toUtc();

    test('can persist date times properly', () {
      adapter.set(keyValueStore, 'key', dateTime);
      verify(keyValueStore.setString('key', '1546394645099'));
    });

    test('can revive date times properly', () {
      when(keyValueStore.getString('key')).thenReturn('1546394645099');

      final storedDateTime = adapter.get(keyValueStore, 'key');
      expect(storedDateTime, dateTime);
    });

    test('handles retrieving null datetimes gracefully', () {
      when(keyValueStore.getString('key')).thenReturn(null);

      final storedDateTime = adapter.get(keyValueStore, 'key');
      expect(storedDateTime, isNull);
    });

    test('handles persisting null datetimes gracefully', () {
      adapter.set(keyValueStore, 'key', null);
      verify(keyValueStore.setString('key', null));
    });
  });
}
