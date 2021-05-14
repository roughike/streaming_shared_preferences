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
  group('EnumAdapter', () {
    late MockSharedPreferences preferences;

    setUp(() {
      preferences = MockSharedPreferences();
    });

    final adapter = EnumAdapter<TestEnum>(
      values: TestEnum.values
    );
    final enumValue = TestEnum.valueTwo;

    test('can persist enums properly', () {
      adapter.setValue(preferences, 'key', enumValue);

      final String value =
          verify(preferences.setString('key', captureAny)).captured.single;
      expect(value, isNotNull);
      expect(value, 'valueTwo');
    });

    test('can revive enums properly', () {
      when(preferences.getString('key')).thenReturn('valueTwo');

      final storedEnum = adapter.getValue(preferences, 'key');
      expect(storedEnum, isNotNull);
      expect(storedEnum, enumValue);
    });

    test('handles retrieving null enums gracefully', () {
      when(preferences.getString('key')).thenReturn(null);

      final storedEnum = adapter.getValue(preferences, 'key');
      expect(storedEnum, isNull);
    });
  });
}

enum TestEnum {
  valueOne,
  valueTwo
}
