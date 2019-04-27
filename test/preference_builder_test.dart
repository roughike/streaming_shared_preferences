import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streaming_shared_preferences/streaming_shared_preferences.dart';

import 'mocks.dart';

void main() {
  group('PreferenceBuilder', () {
    MockSharedPreferences preferences;
    StreamController<String> keyChanges;
    TestPreference preference;

    setUp(() {
      preferences = MockSharedPreferences();
      keyChanges = StreamController<String>();
      preference = TestPreference(preferences, keyChanges);

      // Disable throwing errors for tests when Preference is listened suspiciously
      // many times in a short time period.
      debugTrackOnListenEvents = false;
    });

    tearDown(() {
      debugTrackOnListenEvents = true;
    });

    test('passing null Preference throws an error', () {
      expect(
        () => PreferenceBuilder(null, builder: (_, __) => null),
        throwsA(isInstanceOf<AssertionError>()),
      );
    });

    test('passing null PreferenceWidgetBuilder throws an error', () {
      expect(
        () => PreferenceBuilder(preference, builder: null),
        throwsA(isInstanceOf<AssertionError>()),
      );
    });

    testWidgets(
        'initial build is done with the default value of the preference',
        (tester) async {
      await tester.pumpWidget(
        PreferenceBuilder<String>(
          preference,
          builder: (context, value) {
            return Text(value, textDirection: TextDirection.ltr);
          },
        ),
      );

      expect(find.text('default value'), findsOneWidget);
    });

    testWidgets(
        'initial build is done with the default value of the preference',
        (tester) async {
      await tester.pumpWidget(
        PreferenceBuilder<String>(
          preference,
          builder: (context, value) {
            return Text(value, textDirection: TextDirection.ltr);
          },
        ),
      );

      // Whenever a String with key "test" is retrieved the next time, return
      // the text "updated value".
      when(preferences.getString('test')).thenReturn('updated value');

      // Value does not matter in a test case as the preferences are mocked.
      // This just tells the preference that something was updated.
      preference.set(null);

      await tester.pump();

      expect(find.text('updated value'), findsOneWidget);
    });

    testWidgets('throws an error if a preference is swapped on the fly',
        (tester) async {
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (_, stateSetter) {
            return PreferenceBuilder<String>(
              // Create a new Preference on every rebuild
              TestPreference(preferences, keyChanges),

              builder: (context, value) {
                return GestureDetector(
                  onTap: () => stateSetter(() {}),
                  child: Text('X', textDirection: TextDirection.ltr),
                );
              },
            );
          },
        ),
      );

      // Trigger a rebuild
      await tester.tap(find.text('X'));
      await tester.pump();

      final exception = tester.takeException();
      expect(exception, isNotNull);
      expect(exception, isInstanceOf<PreferenceMismatchError>());
    });

    testWidgets('can rebuild infinitely with a reused Preference object',
        (tester) async {
      debugTrackOnListenEvents = true;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (_, stateSetter) {
            return PreferenceBuilder<String>(
              preference,
              builder: (context, value) {
                return GestureDetector(
                  onTap: () => stateSetter(() {}),
                  child: Text('X', textDirection: TextDirection.ltr),
                );
              },
            );
          },
        ),
      );

      await tester.tap(find.text('X'));
      await tester.pump();

      await tester.tap(find.text('X'));
      await tester.pump();

      await tester.tap(find.text('X'));
      await tester.pump();

      await tester.tap(find.text('X'));
      await tester.pump();

      final exception = tester.takeException();
      expect(exception, isNull);
    });
  });
}

class TestPreference extends Preference<String> {
  // ignore: non_constant_identifier_names
  TestPreference(
    SharedPreferences preferences,
    StreamController<String> keyChanges,
  ) : super.$$_private(
          preferences,
          'test',
          'default value',
          StringAdapter.instance,
          keyChanges,
        );
}
