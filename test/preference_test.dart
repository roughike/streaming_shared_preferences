import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:mockito/mockito.dart';
import 'package:streaming_shared_preferences/src/preference.dart';
import 'package:streaming_shared_preferences/streaming_shared_preferences.dart';
import 'package:test/test.dart';

import '../test/mocks.dart';

class _TestValueAdapter extends PreferenceAdapter<String> {
  @override
  String get(preferences, key) {
    return preferences.getString(key);
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
    Preference<String> preference;

    setUp(() {
      preferences = MockSharedPreferences();
      adapter = _TestValueAdapter();
      keyChanges = StreamController<String>.broadcast();

      // Disable throwing errors for tests when Preference is listened suspiciously
      // many times in a short time period.
      expect(debugTrackOnListenEvents, true);
      debugTrackOnListenEvents = false;

      // ignore: deprecated_member_use_from_same_package
      preference = Preference.$$_private(
        preferences,
        'key',
        'default value',
        adapter,
        keyChanges,
      );
    });

    tearDown(() {
      debugTrackOnListenEvents = true;
    });

    test('calling set() calls the correct key and emits key updates', () {
      preference.set('value1');
      preference.set('value2');
      preference.set('value3');

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

    test('calling set() or clear() on a Preference with null key throws', () {
      final pref =
          Preference.$$_private(preferences, null, '', adapter, keyChanges);

      expect(pref.clear, throwsA(const TypeMatcher<UnsupportedError>()));
      expect(
        () => pref.set(''),
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

    test('throws when listened to 4 times in one second', () async {
      debugTrackOnListenEvents = true;

      FlutterError emittedError;
      FlutterError reportedError;

      FlutterError.onError = (details) {
        reportedError = details.exception;
      };

      try {
        debugResetOnListenLog();
        var time = DateTime.now();

        debugObtainCurrentTime = () => time;
        preference.listen(null);

        time = time.add(Duration(milliseconds: 250));
        preference.listen(null);

        time = time.add(Duration(milliseconds: 250));
        preference.listen(null);

        // Listened to 4 times in a 999 millisecond time period
        time = time.add(Duration(milliseconds: 249));
        await preference.listen(null).asFuture();
      } catch (e) {
        emittedError = e;
      }

      final errorMessage =
          'Called onListen() on a Preference with a key "key" suspiciously '
          'many times on a short time frame.\n\n'
          'This error usually happens because of creating a new Preference '
          'multiple times when using the StreamBuilder widget. If you pass '
          'StreamingSharedPreferences.getXYZ() into StreamBuilder directly, '
          'a new instance of a Preference is created on every rebuild. '
          'This is highly discouraged, because it will refetch a value from '
          'persistent storage every time the widget rebuilds.\n\n'
          'To combat this issue, cache the value returned by StreamingShared'
          'Preferences.getXYZ() and pass the returned Preference object to your StreamBuilder widget.\n\n'
          'For more information, see the StreamingSharedPreferences '
          'documentation or the README at: https://github.com/roughike/streaming_shared_preferences';

      expect(emittedError, isNotNull);
      expect(emittedError.message, errorMessage);

      expect(reportedError, isNotNull);
      expect(reportedError.message, errorMessage);
    });

    test(
        'does not throw if listened to multiple times in a reasonable time period',
        () async {
      debugTrackOnListenEvents = true;
      debugResetOnListenLog();

      var time = DateTime.now();

      debugObtainCurrentTime = () => time;
      preference.listen(null);

      time = time.add(Duration(milliseconds: 250));
      preference.listen(null);

      time = time.add(Duration(milliseconds: 250));
      preference.listen(null);

      time = time.add(Duration(milliseconds: 250));
      preference.listen(null);

      time = time.add(Duration(milliseconds: 250));
      preference.listen(null);

      time = time.add(Duration(milliseconds: 250));
      preference.listen(null);
    });
  });
}
