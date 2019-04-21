import 'dart:async';

import 'package:mockito/mockito.dart';
import 'package:streaming_shared_preferences/src/preference.dart';
import 'package:streaming_shared_preferences/streaming_shared_preferences.dart';
import 'package:test_api/test_api.dart';

import '../test/mocks.dart';

class _TestValueAdapter extends PreferenceAdapter<String> {
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
  group('Preference', () {
    MockSharedPreferences preferences;
    _TestValueAdapter adapter;
    StreamController<String> keyChanges;
    Preference<String> storedValue;

    setUp(() {
      preferences = MockSharedPreferences();
      adapter = _TestValueAdapter();
      keyChanges = StreamController<String>.broadcast();

      // ignore: deprecated_member_use_from_same_package
      storedValue = Preference.$$_private(
        preferences: preferences,
        key: 'key',
        defaultValue: 'default value',
        adapter: adapter,
        keyChanges: keyChanges,
      );
    });

    test('calling set() calls the correct key and emits key updates', () {
      storedValue.set('value1');
      storedValue.set('value2');
      storedValue.set('value3');

      verifyInOrder([
        preferences.setString('key', 'value1'),
        preferences.setString('key', 'value2'),
        preferences.setString('key', 'value3'),
      ]);

      expect(keyChanges.stream, emitsInOrder(['key', 'key', 'key']));
    });

    test('calling clear() calls delegate and removes key', () async {
      storedValue.clear();

      verify(preferences.remove('key'));

      expect(keyChanges.stream, emits('key'));
    });

    test('starts with the latest value whenever listened to', () {
      when(preferences.getString('key')).thenReturn('1');
      expect(storedValue, emits('1'));

      when(preferences.getString('key')).thenReturn('2');
      expect(storedValue, emits('2'));

      when(preferences.getString('key')).thenReturn('3');
      expect(storedValue, emits('3'));
    });
  });
}
