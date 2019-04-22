import 'dart:async';

import 'package:flutter/services.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streaming_shared_preferences/streaming_shared_preferences.dart';
import 'package:test/test.dart';

import 'mocks.dart';

void main() {
  group('StreamingKeyValueStore', () {
    MockSharedPreferences delegate;
    StreamingSharedPreferences preferences;

    setUpAll(() async {
      // SharedPreferences calls "getAll" through a method channel initially when
      // creating an instance of it.
      //
      // This will crash in tests by default, so this is a minimal glue code to
      // make sure that we can run the test below without crashes.
      const channel = MethodChannel('plugins.flutter.io/shared_preferences');
      channel.setMockMethodCallHandler((call) async {
        return call.method == 'getAll' ? {} : null;
      });

      // [debugObtainSharedPreferencesInstance] should be non-null and return
      // a [Future] that completes with an instance of SharedPreferences.
      //
      // Otherwise tests might run just fine, but we can't be sure that the
      // instance obtainer is not broken in production.
      final instance = await debugObtainSharedPreferencesInstance;
      expect(debugObtainSharedPreferencesInstance, isNotNull);
      expect(instance, const TypeMatcher<SharedPreferences>());
    });

    setUp(() async {
      delegate = MockSharedPreferences();

      // Disable throwing errors for tests when Preference is listened suspiciously
      // many times in a short time period.
      debugTrackOnListenEvents = false;

      // Swap the instance obtainer with one that always returns a mocked verison
      // of shared preferences.
      debugObtainSharedPreferencesInstance = Future.value(delegate);
      preferences = await StreamingSharedPreferences.instance;
    });

    tearDown(() {
      debugResetStreamingSharedPreferencesInstance();
      debugTrackOnListenEvents = true;
    });

    test('obtaining instance calls delegate only once', () async {
      var obtainCount = 0;

      // Need to reset the instance as the singleton was already obtained in
      // the [setUp] method in tests.
      debugResetStreamingSharedPreferencesInstance();

      // Swap the instance obtainer to a spying one that increases the counter
      // whenever it's called.
      debugObtainSharedPreferencesInstance = Future(() {
        obtainCount++;
        return MockSharedPreferences();
      });

      await StreamingSharedPreferences.instance;
      await StreamingSharedPreferences.instance;
      await StreamingSharedPreferences.instance;

      expect(obtainCount, 1);
    });

    test('forwards all method invocations and parameters to the delegate',
        () async {
      preferences.getKeys().listen(null);
      preferences.getBool('boolKey', defaultsTo: false).listen(null);
      preferences.getInt('intKey', defaultsTo: 0).listen(null);
      preferences.getDouble('doubleKey', defaultsTo: 0).listen(null);
      preferences.getString('stringKey', defaultsTo: '').listen(null);
      preferences.getStringList('stringListKey', defaultsTo: []).listen(null);

      preferences.setBool('boolKey', true);
      preferences.setInt('intKey', 1337);
      preferences.setDouble('doubleKey', 13.37);
      preferences.setString('stringKey', 'stringValue');
      preferences.setStringList('stringListKey', ['stringListValue']);

      preferences.remove('removeKey');

      // Calling clear() calls delegate.getKeys() - so we must return a non-null
      // value here.
      when(delegate.getKeys()).thenReturn(Set());
      preferences.clear();

      verifyInOrder([
        // Getters
        delegate.getKeys(),
        delegate.getBool('boolKey'),
        delegate.getInt('intKey'),
        delegate.getDouble('doubleKey'),
        delegate.getString('stringKey'),
        delegate.getStringList('stringListKey'),

        // Setters
        delegate.setBool('boolKey', true),
        delegate.setInt('intKey', 1337),
        delegate.setDouble('doubleKey', 13.37),
        delegate.setString('stringKey', 'stringValue'),
        delegate.setStringList('stringListKey', ['stringListValue']),

        // Other
        delegate.remove('removeKey'),

        // Calling clear() should first get the keys and then call clear() on
        // the delegate. calling getKeys() after clear() returns an empty set
        // of keys, so it would not notify about the deleted keys properly.
        delegate.getKeys(),
        delegate.clear(),
      ]);

      verifyNoMoreInteractions(delegate);
    });

    test('settable values should be... settable', () {
      // These invocations make sure that a ".set(..)" method exists and is
      // accessible for all these getters. If the test doesn't crash, it's considered
      // a passing test.
      preferences.getBool('key', defaultsTo: false).set(true);
      preferences.getInt('key', defaultsTo: 0).set(1);
      preferences.getDouble('key', defaultsTo: 0).set(1);
      preferences.getString('key', defaultsTo: '').set('');
      preferences.getStringList('key', defaultsTo: []).set(['a']);

      // Casting "getKeys()" to dynamic and trying to call ".set(..)" on it should
      // throw an error.
      expect(
        () => (preferences.getKeys() as dynamic).set(null),
        throwsA(const TypeMatcher<Error>()),
      );
    });

    group('getKeys() tests', () {
      test('getKeys() - can listen to multiple times', () {
        when(delegate.getKeys()).thenReturn(Set.from(['first', 'second']));
        final stream = preferences.getKeys();

        // If this doesn't crash the test, the test is considered a passing test.
        stream.listen((_) {});
        stream.listen((_) {});
        stream.listen((_) {});
      });

      test('when keys are null or empty, emits an empty set', () async {
        when(delegate.getKeys()).thenReturn(null);
        await expectLater(preferences.getKeys(), emits(Set()));

        when(delegate.getKeys()).thenReturn(Set());
        expect(preferences.getKeys(), emits(Set()));
      });

      test('initial values', () {
        when(delegate.getKeys()).thenReturn(Set.from(['first', 'second']));
        expect(preferences.getKeys(), emits(Set.from(['first', 'second'])));
      });

      test('getKeys().value() - initial values', () {
        when(delegate.getKeys()).thenReturn(Set.from(['first', 'second']));
        expect(preferences.getKeys(), emits(Set.from(['first', 'second'])));
      });

      test('setting a value emits latest keys in the stream', () async {
        final keys = preferences.getKeys();
        var count = 0;

        /// This might seem wonky, but it is actually testing the relevant use
        /// case. Every time a "setXYZ()" is called, we should fetch keys using
        /// delegate.getKey() and then emit them. Although what delegate.getKeys()
        /// returns doesn't matter in a test case, we're returning what would be
        /// returned in a real scenario so that it's easier to follow.
        when(delegate.getKeys()).thenAnswer((_) {
          count++;

          switch (count) {
            case 1:
              return Set.from(['key1']);
            case 2:
              return Set.from(['key1', 'key2']);
            case 3:
              return Set.from(['key1', 'key2', 'key3']);
            case 4:
              return Set.from(['key1', 'key2', 'key3', 'key4']);
            case 5:
              return Set.from(['key1', 'key2', 'key3', 'key4', 'key5']);
            case 6:
              return Set.from(['key1', 'key2', 'key3', 'key4', 'key5', 'key6']);
          }
        });

        preferences.setBool('key1', true);
        preferences.setInt('key2', 2);
        preferences.setDouble('key3', 3.0);
        preferences.setString('key4', 'value4');
        preferences.setStringList('key5', ['value5']);
        preferences.setCustomValue('key6', '', adapter: StringAdapter.instance);

        expect(
          keys,
          emitsInOrder([
            // setting a bool
            Set.from(['key1']),

            // setting an int
            Set.from(['key1', 'key2']),

            // setting a double
            Set.from(['key1', 'key2', 'key3']),

            // setting a String
            Set.from(['key1', 'key2', 'key3', 'key4']),

            // setting a String list
            Set.from(['key1', 'key2', 'key3', 'key4', 'key5']),

            // setting a custom value
            Set.from(['key1', 'key2', 'key3', 'key4', 'key5', 'key6']),
          ]),
        );
      });

      test(
        'calling .value() has a different result after setting values',
        () async {
          final keys = preferences.getKeys();
          var count = 0;

          /// This might seem wonky, but it is actually testing the relevant use
          /// case. Every time a "setXYZ()" is called, we should fetch keys using
          /// delegate.getKey() and then emit them. Although what delegate.getKeys()
          /// returns doesn't matter in a test case, we're returning what would be
          /// returned in a real scenario so that it's easier to follow.
          when(delegate.getKeys()).thenAnswer((_) {
            count++;

            switch (count) {
              case 1:
                return Set.from(['key1']);
              case 2:
                return Set.from(['key1', 'key2']);
              case 3:
                return Set.from(['key1', 'key2', 'key3']);
              case 4:
                return Set.from(['key1', 'key2', 'key3', 'key4']);
              case 5:
                return Set.from(['key1', 'key2', 'key3', 'key4', 'key5']);
            }
          });

          preferences.setBool('key1', true);
          expect(keys.value(), Set.from(['key1']));

          preferences.setInt('key2', 2);
          expect(keys.value(), Set.from(['key1', 'key2']));

          preferences.setDouble('key3', 3.0);
          expect(keys.value(), Set.from(['key1', 'key2', 'key3']));

          preferences.setString('key4', 'value4');
          expect(keys.value(), Set.from(['key1', 'key2', 'key3', 'key4']));

          preferences.setStringList('key5', ['value5']);
          expect(
            keys.value(),
            Set.from(['key1', 'key2', 'key3', 'key4', 'key5']),
          );
        },
      );
    });

    group('boolean tests', () {
      setUp(() {
        when(delegate.getBool('myTrueBool')).thenReturn(true);
        when(delegate.getBool('myFalseBool')).thenReturn(false);
        when(delegate.getBool('myNullBool')).thenReturn(null);
      });

      test('getBool() - can listen to multiple times', () {
        final stream = preferences.getBool('myTrueBool', defaultsTo: false);

        // If this doesn't crash the test, the test is considered a passing test.
        stream.listen((_) {});
        stream.listen((_) {});
        stream.listen((_) {});
      });

      test('getBool().stream() - initial values', () {
        expect(
          preferences.getBool('myTrueBool', defaultsTo: false),
          emits(true),
        );

        expect(
          preferences.getBool('myFalseBool', defaultsTo: true),
          emits(false),
        );

        expect(
          preferences.getBool('myNullBool', defaultsTo: true),
          emits(true),
        );

        expect(
          preferences.getBool('myNullBool', defaultsTo: false),
          emits(false),
        );
      });

      test('getBool().value() - initial values', () {
        expect(
          preferences.getBool('myTrueBool', defaultsTo: false).value(),
          true,
        );

        expect(
          preferences.getBool('myFalseBool', defaultsTo: true).value(),
          false,
        );

        expect(
          preferences.getBool('myNullBool', defaultsTo: true).value(),
          true,
        );

        expect(
          preferences.getBool('myNullBool', defaultsTo: false).value(),
          false,
        );
      });

      test('getBool().value()', () async {
        final storedBool = preferences.getBool('key1', defaultsTo: false);
        expect(storedBool.value(), isFalse);

        when(delegate.getBool('key1')).thenReturn(true);
        expect(storedBool.value(), isTrue);

        when(delegate.getBool('key1')).thenReturn(false);
        expect(
          preferences.getBool('key1', defaultsTo: true).value(),
          isFalse,
        );

        when(delegate.getBool('key1')).thenReturn(null);
        expect(
          preferences.getBool('key1', defaultsTo: true).value(),
          isTrue,
        );

        expect(
          preferences.getBool('key1', defaultsTo: false).value(),
          isFalse,
        );
      });

      test('setBool emits an update in getBool', () async {
        final storedBool = preferences.getBool('key1', defaultsTo: false);

        scheduleMicrotask(() {
          when(delegate.getBool('key1')).thenReturn(true);

          // Setting value to null won't matter here as the delegate is just a mock.
          // What we're interested instead is triggering an update in the changed
          // keys stream.
          preferences.setBool('key1', null);
        });

        await expectLater(storedBool, emitsInOrder([false, true]));
      });
    });

    group('int tests', () {
      setUp(() {
        when(delegate.getInt('myInt')).thenReturn(1337);
        when(delegate.getInt('myNullInt')).thenReturn(null);
      });

      test('getInt() - can listen to multiple times', () {
        final stream = preferences.getInt('myInt', defaultsTo: 0);

        // If this doesn't crash the test, the test is considered a passing test.
        stream.listen((_) {});
        stream.listen((_) {});
        stream.listen((_) {});
      });

      test('getInt() - initial values', () {
        expect(preferences.getInt('myInt', defaultsTo: 0), emits(1337));
        expect(preferences.getInt('myNullInt', defaultsTo: 0), emits(0));
        expect(
          preferences.getInt('myNullInt', defaultsTo: 1337),
          emits(1337),
        );
      });

      test('getInt().value() - initial values', () {
        expect(preferences.getInt('myInt', defaultsTo: 0).value(), 1337);
        expect(
          preferences.getInt('myNullInt', defaultsTo: 1337).value(),
          1337,
        );
      });

      test('getInt().value()', () async {
        final storedInt = preferences.getInt('key1', defaultsTo: 0);
        expect(storedInt.value(), 0);

        when(delegate.getInt('key1')).thenReturn(1);
        expect(storedInt.value(), 1);

        when(delegate.getInt('key1')).thenReturn(2);
        expect(preferences.getInt('key1', defaultsTo: 0).value(), 2);

        when(delegate.getInt('key1')).thenReturn(null);
        expect(
          preferences.getInt('key1', defaultsTo: 1).value(),
          1,
        );
      });

      test('setInt emits an update in getInt', () async {
        final storedInt = preferences.getInt('key1', defaultsTo: 1);

        scheduleMicrotask(() {
          when(delegate.getInt('key1')).thenReturn(2);

          // Setting value to null won't matter here as the delegate is just a mock.
          // What we're interested instead is triggering an update in the changed
          // keys stream.
          preferences.setInt('key1', null);
        });

        await expectLater(storedInt, emitsInOrder([1, 2]));
      });
    });

    group('double tests', () {
      setUp(() {
        when(delegate.getDouble('myDouble')).thenReturn(13.37);
        when(delegate.getDouble('myNullDouble')).thenReturn(null);
      });

      test('getDouble() - can listen to multiple times', () {
        final stream = preferences.getDouble('myDouble', defaultsTo: 0);

        // If this doesn't crash the test, the test is considered a passing test.
        stream.listen((_) {});
        stream.listen((_) {});
        stream.listen((_) {});
      });

      test('getDouble() - initial values', () {
        expect(
          preferences.getDouble('myDouble', defaultsTo: 0),
          emits(13.37),
        );

        expect(
          preferences.getDouble('myNullDouble', defaultsTo: 13.37),
          emits(13.37),
        );
      });

      test('getDouble().value() - initial values', () {
        expect(
          preferences.getDouble('myDouble', defaultsTo: 0).value(),
          13.37,
        );

        expect(
          preferences.getDouble('myNullDouble', defaultsTo: 13.37).value(),
          13.37,
        );
      });

      test('getDouble().value()', () async {
        final storedDouble = preferences.getDouble('key1', defaultsTo: 0);
        expect(storedDouble.value(), 0);

        when(delegate.getDouble('key1')).thenReturn(1.1);
        expect(storedDouble.value(), 1.1);

        when(delegate.getDouble('key1')).thenReturn(2.2);
        expect(preferences.getDouble('key1', defaultsTo: 0).value(), 2.2);

        when(delegate.getDouble('key1')).thenReturn(null);
        expect(
          preferences.getDouble('key1', defaultsTo: 1.1).value(),
          1.1,
        );
      });

      test('setDouble emits an update in getDouble', () async {
        final storedDouble = preferences.getDouble('key1', defaultsTo: 1.1);

        scheduleMicrotask(() {
          when(delegate.getDouble('key1')).thenReturn(2.2);

          // Setting value to null won't matter here as the delegate is just a mock.
          // What we're interested instead is triggering an update in the changed
          // keys stream.
          preferences.setDouble('key1', null);
        });

        expect(storedDouble, emitsInOrder([1.1, 2.2]));
      });
    });

    group('String tests', () {
      setUp(() {
        when(delegate.getString('myString')).thenReturn('myValue');
        when(delegate.getString('myNullString')).thenReturn(null);
      });

      test('getString() - can listen to multiple times', () {
        final stream = preferences.getString('myString', defaultsTo: '');

        // If this doesn't crash the test, the test is considered a passing test.
        stream.listen((_) {});
        stream.listen((_) {});
        stream.listen((_) {});
      });

      test('getString() - initial values', () {
        expect(
          preferences.getString('myString', defaultsTo: ''),
          emits('myValue'),
        );

        expect(
          preferences.getString('null-defValue', defaultsTo: 'defaultValue'),
          emits('defaultValue'),
        );
      });

      test('getString().value() - initial values', () {
        expect(
          preferences.getString('myString', defaultsTo: '').value(),
          'myValue',
        );

        expect(
          preferences
              .getString('null-defValue', defaultsTo: 'defaultValue')
              .value(),
          'defaultValue',
        );
      });

      test('getString().value()', () async {
        final storedString = preferences.getString('key1', defaultsTo: '');
        expect(storedString.value(), isEmpty);

        when(delegate.getString('key1')).thenReturn('value 1');
        expect(storedString.value(), 'value 1');

        when(delegate.getString('key1')).thenReturn('value 2');
        expect(
          preferences.getString('key1', defaultsTo: '').value(),
          'value 2',
        );

        when(delegate.getString('key1')).thenReturn(null);
        expect(
          preferences.getString('key1', defaultsTo: 'defaultValue').value(),
          'defaultValue',
        );
      });

      test('setString emits an update in getString Stream', () async {
        final storedString =
            preferences.getString('key1', defaultsTo: 'defaultValue');

        scheduleMicrotask(() {
          when(delegate.getString('key1')).thenReturn('updated string');

          // Setting value to null won't matter here as the delegate is just a mock.
          // What we're interested instead is triggering an update in the changed
          // keys stream.
          preferences.setString('key1', null);
        });

        await expectLater(
          storedString,
          emitsInOrder(['defaultValue', 'updated string']),
        );
      });
    });

    group('String list tests', () {
      setUp(() {
        when(delegate.getStringList('myStringList')).thenReturn(['a', 'b']);
        when(delegate.getStringList('myNullStringList')).thenReturn(null);
        when(delegate.getStringList('myEmptyStringList')).thenReturn([]);
      });

      test('getStringList() - can listen to multiple times', () {
        final stream = preferences.getStringList(
          'myStringList',
          defaultsTo: [],
        );

        // If this doesn't crash the test, the test is considered a passing test.
        stream.listen((_) {});
        stream.listen((_) {});
        stream.listen((_) {});
      });

      test('getStringList() - initial values', () {
        expect(
          preferences.getStringList('myStringList', defaultsTo: []),
          emits(['a', 'b']),
        );

        expect(
          preferences.getStringList(
            'myEmptyStringList',
            defaultsTo: ['nonempty'],
          ),
          emits([]),
        );

        expect(
          preferences.getStringList(
            'myNullStringList',
            defaultsTo: ['default', 'value'],
          ),
          emits(['default', 'value']),
        );
      });

      test('getStringList().value() - initial values', () {
        expect(
          preferences.getStringList('myStringList', defaultsTo: []).value(),
          ['a', 'b'],
        );

        expect(
          preferences.getStringList(
            'null-defValue',
            defaultsTo: ['default', 'value'],
          ).value(),
          ['default', 'value'],
        );
      });

      test('getStringList().value()', () async {
        final storedStringList = preferences.getStringList(
          'key1',
          defaultsTo: [],
        );

        expect(storedStringList.value(), isEmpty);

        when(delegate.getStringList('key1')).thenReturn(['a', 'a']);
        expect(storedStringList.value(), ['a', 'a']);

        when(delegate.getStringList('key1')).thenReturn(['b', 'b']);
        expect(
          preferences.getStringList('key1', defaultsTo: []).value(),
          ['b', 'b'],
        );

        when(delegate.getStringList('key1')).thenReturn(null);
        expect(
          preferences.getStringList(
            'key1',
            defaultsTo: ['default', 'value'],
          ).value(),
          ['default', 'value'],
        );
      });

      test('setStringList emits an update in getStringList', () async {
        final storedString = preferences.getStringList(
          'key1',
          defaultsTo: ['default', 'value'],
        );

        scheduleMicrotask(() {
          when(delegate.getStringList('key1')).thenReturn(['updated', 'value']);

          // Setting value to null won't matter here as the delegate is just a mock.
          // What we're interested instead is triggering an update in the changed
          // keys stream.
          preferences.setStringList('key1', null);
        });

        await expectLater(
          storedString,
          emitsInOrder([
            ['default', 'value'],
            ['updated', 'value'],
          ]),
        );
      });
    });

    test('removing a key triggers an update in value stream', () {
      when(delegate.getString('myString')).thenReturn('initial value');
      final stringValue = preferences.getString('myString', defaultsTo: '');

      scheduleMicrotask(() {
        // We're  only testing that the removal triggers an update in the key stream.
        // While this "when" call here could return anything, we're returning null
        // because that's what would happen in a real scenario.
        when(delegate.getString('myString')).thenReturn(null);
        preferences.remove('myString');
      });

      expect(stringValue, emitsInOrder(['initial value', '']));
    });

    test('clear() triggers update on all existing keys', () {
      when(delegate.getKeys()).thenReturn(Set.from(['key1', 'key2', 'key3']));
      when(delegate.getString(any)).thenReturn('value');

      final value1 = preferences.getString('key1', defaultsTo: '');
      final value2 = preferences.getString('key2', defaultsTo: '');
      final value3 = preferences.getString('key3', defaultsTo: '');

      scheduleMicrotask(() {
        // We're  only testing that calling clear() triggers an update in the key
        // stream for all of the existing keys.
        //
        // While this "when" call here could return anything, we're returning null
        // because that's what would happen in a real scenario.
        when(delegate.getString(any)).thenReturn(null);
        preferences.clear();
      });

      expect(value1, emitsInOrder(['value', '']));
      expect(value2, emitsInOrder(['value', '']));
      expect(value3, emitsInOrder(['value', '']));
    });
  });
}
