import 'dart:async';

import 'package:mockito/mockito.dart';
import 'package:streaming_key_value_store/streaming_key_value_store.dart';
import 'package:test/test.dart';

import '../test/mocks.dart';

class _TestValueAdapter extends StoredValueAdapter<String> {
  @override
  String get(keyValueStore, key) {
    return keyValueStore.getString(key);
  }

  @override
  Future<bool> set(keyValueStore, key, value) {
    return keyValueStore.setString(key, value);
  }
}

void main() {
  group('StoredValue', () {
    MockKeyValueStore keyValueStore;
    _TestValueAdapter adapter;
    StreamController<String> keyChanges;
    StoredValue<String> preference;

    setUp(() {
      keyValueStore = MockKeyValueStore();
      adapter = _TestValueAdapter();
      keyChanges = StreamController<String>.broadcast();

      // ignore: deprecated_member_use_from_same_package
      preference = StoredValue.$$_private(
        keyValueStore,
        'key',
        'default value',
        adapter,
        keyChanges,
      );
    });

    test('calling set() calls the correct key and emits key updates', () {
      preference.set('value1');
      preference.set('value2');
      preference.set('value3');

      verifyInOrder([
        keyValueStore.setString('key', 'value1'),
        keyValueStore.setString('key', 'value2'),
        keyValueStore.setString('key', 'value3'),
      ]);

      expect(keyChanges.stream, emitsInOrder(['key', 'key', 'key']));
    });

    test('calling clear() calls delegate and removes key', () async {
      preference.clear();

      verify(keyValueStore.remove('key'));

      expect(keyChanges.stream, emits('key'));
    });

    test('calling set() or clear() on a StoredValue with null key throws', () {
      final pref =
          StoredValue.$$_private(keyValueStore, null, '', adapter, keyChanges);

      expect(pref.clear, throwsA(const TypeMatcher<UnsupportedError>()));
      expect(
        () => pref.set(''),
        throwsA(const TypeMatcher<UnsupportedError>()),
      );
    });

    test('starts with the latest value whenever listened to', () {
      when(keyValueStore.getString('key')).thenReturn('1');
      expect(preference, emits('1'));

      when(keyValueStore.getString('key')).thenReturn('2');
      expect(preference, emits('2'));

      when(keyValueStore.getString('key')).thenReturn('3');
      expect(preference, emits('3'));
    });
  });
}
