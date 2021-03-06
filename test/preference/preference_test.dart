import 'dart:async';

import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streaming_shared_preferences/src/preference/preference.dart';
import 'package:streaming_shared_preferences/streaming_shared_preferences.dart';
import 'package:test/test.dart';

class MockSharedPreferences extends Mock implements SharedPreferences {
  @override
  Future<bool> setString(String? key, String? value) {
    return super.noSuchMethod(
      Invocation.method(#setString, [key, value]),
      returnValue: Future.value(true),
      returnValueForMissingStub: Future.value(true),
    );
  }

  @override
  Future<bool> remove(String? key) {
    return super.noSuchMethod(
      Invocation.method(#remove, [key]),
      returnValue: Future.value(true),
      returnValueForMissingStub: Future.value(true),
    );
  }
}

void main() {
  group('Preference', () {
    late MockSharedPreferences preferences;
    late _TestValueAdapter adapter;
    late StreamController<String> keyChanges;
    late Preference<String> preference;

    setUp(() {
      preferences = MockSharedPreferences();
      adapter = _TestValueAdapter();
      keyChanges = StreamController<String>.broadcast();

      preference = Preference.$$_private(
        preferences,
        'key',
        'default value',
        adapter,
        keyChanges,
      );
    });
    tearDown(() {
      keyChanges.close();
    });

    Future<void> _updateValue(String newValue) async {
      when(preferences.getString('key')).thenReturn(newValue);

      // The value passed to setValue does not matter in tests - it just merely
      // tells the preference that something just changed.
      await preference.setValue('');
    }

    Future<void> _clear() async {
      when(preferences.getString('key')).thenReturn(null);

      // The value passed to setValue does not matter in tests - it just merely
      // tells the preference that something just changed.
      await preference.clear();
    }

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

    test(
        'calling setValue() or clear() on a Preference with the getKeys key throws',
        () {
      final pref = Preference.$$_private(
        preferences,
        // ignore: invalid_use_of_internal_member
        Preference.$$_getKeysKey,
        '',
        adapter,
        keyChanges,
      );

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

    test('does not emit same value more than once in a row for one listener',
        () async {
      int updateCount = 0;
      preference.listen((_) => updateCount++);

      await _updateValue('new value');
      await _updateValue('new value');
      await _updateValue('new value');

      // Changed from "default value" to "new value"
      expect(updateCount, 2);

      await _updateValue('another value 1');
      await _updateValue('another value 2');
      await _updateValue('another value 3');

      // Changed from "new value" to "another value" 3 times
      expect(updateCount, 5);
    });

    // There was a bug where reusing a Preference between multiple listeners
    // only propagated the change to the first one. This test is here to prevent
    // that from happening again.
    //
    // For more context, see: https://github.com/roughike/streaming_shared_preferences/pull/1
    test('emits each value change to all listeners', () async {
      late String value1;
      late String value2;
      late String value3;

      preference.listen((value) => value1 = value);
      preference.listen((value) => value2 = value);
      preference.listen((value) => value3 = value);

      await _clear();

      expect(value1, 'default value');
      expect(value2, 'default value');
      expect(value3, 'default value');

      await _updateValue('first change');

      expect(value1, 'first change');
      expect(value2, 'first change');
      expect(value3, 'first change');

      await _updateValue('second change');

      expect(value1, 'second change');
      expect(value2, 'second change');
      expect(value3, 'second change');
    });
  });
}

class _TestValueAdapter extends PreferenceAdapter<String> {
  @override
  String? getValue(preferences, key) {
    return preferences.getString(key);
  }

  @override
  Future<bool> setValue(keyValueStore, key, value) {
    return keyValueStore.setString(key, value);
  }
}
