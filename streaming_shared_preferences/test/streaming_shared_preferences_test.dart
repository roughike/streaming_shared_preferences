import 'package:flutter/services.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streaming_key_value_store/streaming_key_value_store.dart';
import 'package:streaming_shared_preferences/src/streaming_shared_preferences.dart';
import 'package:test/test.dart';

class MockSharedPreferences extends Mock implements SharedPreferences {}

void main() {
  group('StreamingSharedPreferences', () {
    MockSharedPreferences delegate;
    KeyValueStore keyValueStore;

    setUpAll(() async {
      // [debugObtainSharedPreferencesInstance] should be non-null and return
      // a [Future] that completes with an instance of SharedPreferences.
      //
      // Otherwise tests might run just fine, but we can't be sure that the
      // instance obtainer is not broken in production.

      const channel = MethodChannel('plugins.flutter.io/shared_preferences');
      channel.setMockMethodCallHandler((call) async {
        return call.method == 'getAll' ? {} : null;
      });

      final instance = await debugObtainSharedPreferencesInstance;
      expect(debugObtainSharedPreferencesInstance, isNotNull);
      expect(instance, const TypeMatcher<SharedPreferences>());
    });

    setUp(() async {
      delegate = MockSharedPreferences();
      keyValueStore = SharedPreferencesKeyValueStore(delegate);

      debugObtainSharedPreferencesInstance = Future.value(delegate);
    });

    tearDown(() {
      debugResetStreamingSharedPreferencesInstance();
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

    test('streamingInstance returns a non-null StreamingKeyValueStore',
        () async {
      final streamingKeyValueStore = await StreamingSharedPreferences.instance;

      expect(streamingKeyValueStore, isNotNull);
      expect(
        streamingKeyValueStore,
        const TypeMatcher<StreamingSharedPreferences>(),
      );
    });

    test('forwards all method calls to shared prefs', () async {
      when(delegate.getKeys()).thenReturn(Set.from(['first', 'second']));
      when(delegate.getBool('boolKey')).thenReturn(true);
      when(delegate.getInt('intKey')).thenReturn(1);
      when(delegate.getDouble('doubleKey')).thenReturn(1.0);
      when(delegate.getString('stringKey')).thenReturn('value');
      when(delegate.getStringList('stringListKey'))
          .thenReturn(['first', 'second']);

      final keys = keyValueStore.getKeys();
      final boolValue = keyValueStore.getBool('boolKey');
      final intValue = keyValueStore.getInt('intKey');
      final doubleValue = keyValueStore.getDouble('doubleKey');
      final stringValue = keyValueStore.getString('stringKey');
      final stringListValue = keyValueStore.getStringList('stringListKey');

      keyValueStore.setBool('boolKey', true);
      keyValueStore.setBool('boolKey', false);
      keyValueStore.setInt('intKey', 1);
      keyValueStore.setDouble('doubleKey', 1);
      keyValueStore.setString('stringKey', 'value');
      keyValueStore.setStringList('stringListKey', ['first', 'second']);
      keyValueStore.remove('keyToRemove');
      keyValueStore.clear();

      expect(keys, ['first', 'second']);
      expect(boolValue, isTrue);
      expect(intValue, 1);
      expect(doubleValue, 1);
      expect(stringValue, 'value');
      expect(stringListValue, ['first', 'second']);

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
        delegate.setBool('boolKey', false),
        delegate.setInt('intKey', 1),
        delegate.setDouble('doubleKey', 1),
        delegate.setString('stringKey', 'value'),
        delegate.setStringList('stringListKey', ['first', 'second']),

        // Removal
        delegate.remove('keyToRemove'),
        delegate.clear(),
      ]);
    });

    test('getKeys returns null even if shared prefs returns an empty Set', () {
      // If there's no keys but an empty Set is returned, the correct behavior
      // is still to return null.
      when(delegate.getKeys()).thenReturn(Set());
      expect(keyValueStore.getKeys(), isNull);
    });
  });
}
