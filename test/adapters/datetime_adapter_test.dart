import 'package:mockito/mockito.dart';
import 'package:streaming_shared_preferences/streaming_shared_preferences.dart';
import 'package:test_api/test_api.dart';

import '../mocks.dart';

void main() {
  group('DateTimeAdapter', () {
    MockSharedPreferences preferences;

    setUp(() {
      preferences = MockSharedPreferences();
    });

    final adapter = DateTimeAdapter();
    final dateTime = DateTime(2019, 01, 02, 03, 04, 05, 99).toUtc();

    test('can persist date times properly', () {
      adapter.set(preferences, 'key', dateTime);
      verify(preferences.setString('key', '1546394645099'));
    });

    test('can revive date times properly', () {
      when(preferences.getString('key')).thenReturn('1546394645099');

      final storedDateTime = adapter.get(preferences, 'key');
      expect(storedDateTime, dateTime);
    });

    test('handles retrieving null datetimes gracefully', () {
      when(preferences.getString('key')).thenReturn(null);

      final storedDateTime = adapter.get(preferences, 'key');
      expect(storedDateTime, isNull);
    });

    test('handles persisting null datetimes gracefully', () {
      adapter.set(preferences, 'key', null);
      verify(preferences.setString('key', null));
    });
  });
}
