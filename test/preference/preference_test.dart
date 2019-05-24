import 'dart:async';

import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streaming_shared_preferences/src/preference/preference.dart';
import 'package:streaming_shared_preferences/streaming_shared_preferences.dart';
import 'package:test/test.dart';

class MockSharedPreferences extends Mock implements SharedPreferences {}

void main() {
  group('Preference', () {
    MockSharedPreferences preferences;
    _TestValueAdapter adapter;
    StreamController<String> keyChanges;
    Preference<String> preference;

    setUp(() {
      preferences = MockSharedPreferences();
      adapter = _TestValueAdapter();
      keyChanges = StreamController<String>.broadcast();

      // ignore: deprecated_member_use_from_same_package
      preference = Preference.$$_private(
        preferences,
        'key',
        'default value',
        adapter,
        keyChanges,
      );
    });

    test('calling setValue() calls the correct key and emits key updates', () {
      preference.setValue('value1');
      preference.setValue('value2');
      preference.setValue('value3');

      verifyInOrder([
        preferences.setString('key', 'value1'),
        preferences.setString('key', 'value2'),
        preferences.setString('key', 'value3'),
      ]);

      expect(keyChanges.stream, emitsInOrder(['key', 'key', 'key']));
    });

    test('calling clear() calls delegate and removes key', () async {
      preference.clear();

      verify(preferences.remove('key'));

      expect(keyChanges.stream, emits('key'));
    });

    test('calling setValue() or clear() on a Preference with null key throws',
        () {
      final pref =
          Preference.$$_private(preferences, null, '', adapter, keyChanges);

      expect(pref.clear, throwsA(const TypeMatcher<UnsupportedError>()));
      expect(
        () => pref.setValue(''),
        throwsA(const TypeMatcher<UnsupportedError>()),
      );
    });

    test('starts with the latest value whenever listened to', () {
      when(preferences.getString('key')).thenReturn('1');
      expect(preference, emits('1'));

      when(preferences.getString('key')).thenReturn('2');
      expect(preference, emits('2'));

      when(preferences.getString('key')).thenReturn('3');
      expect(preference, emits('3'));
    });

    test('does not emit same value more than once in a row', () async {
      int updateCount = 0;
      preference.listen((_) => updateCount++);

      when(preferences.getString('key')).thenReturn('new value');
      await preference.setValue(null);

      when(preferences.getString('key')).thenReturn('new value');
      await preference.setValue(null);

      when(preferences.getString('key')).thenReturn('new value');
      await preference.setValue(null);

      // Changed from "default value" to "new value"
      expect(updateCount, 2);

      when(preferences.getString('key')).thenReturn('another value 1');
      await preference.setValue(null);

      when(preferences.getString('key')).thenReturn('another value 2');
      await preference.setValue(null);

      when(preferences.getString('key')).thenReturn('another value 3');
      await preference.setValue(null);

      // Changed from "new value" to "another value" 3 times
      expect(updateCount, 5);
    });
  });
}

class _TestValueAdapter extends PreferenceAdapter<String> {
  @override
  String getValue(preferences, key) {
    return preferences.getString(key);
  }

  @override
  Future<bool> setValue(keyValueStore, key, value) {
    return keyValueStore.setString(key, value);
  }
}
