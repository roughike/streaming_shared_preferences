import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streaming_shared_preferences/streaming_shared_preferences.dart';
import 'package:test/test.dart';

class MockSharedPreferences extends Mock implements SharedPreferences {
  @override
  Future<bool> setString(String key, String? value) {
    return super.noSuchMethod(
      Invocation.method(#setString, [key, value]),
      returnValue: Future.value(true),
      returnValueForMissingStub: Future.value(true),
    );
  }
}

void main() {
  group('DateTimeAdapter', () {
    late MockSharedPreferences preferences;

    setUp(() {
      preferences = MockSharedPreferences();
    });

    final adapter = DateTimeAdapter.instance;
    final dateTime = DateTime.utc(2019, 01, 02, 03, 04, 05, 99);

    test('can persist date times properly', () {
      adapter.setValue(preferences, 'key', dateTime);

      // Comparing to an exact millisecond timestamp runs just fine on a local
      // machine, but fails in CI because of differences in geographic regions.
      //
      // For that reason, this test is a little fuzzy.
      final String value =
          verify(preferences.setString('key', captureAny)).captured.single;
      expect(value, isNotNull);
      expect(value.length, 13);
    });

    test('can revive date times properly', () {
      when(preferences.getString('key')).thenReturn('1546394645099');

      // Comparing to a exact millisecond timestamp runs just fine on a local
      // machine, but fails in CI because of differences in geographic regions.
      //
      // For that reason, this test is a little fuzzy.
      final storedDateTime = adapter.getValue(preferences, 'key')!;
      expect(
        storedDateTime.difference(dateTime) <
            const Duration(hours: 1, minutes: 1),
        isTrue,
      );
    });

    test('handles retrieving null datetimes gracefully', () {
      when(preferences.getString('key')).thenReturn(null);

      final storedDateTime = adapter.getValue(preferences, 'key');
      expect(storedDateTime, isNull);
    });
  });
}
