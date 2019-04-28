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

    testWidgets('initial build is done with current value of the preference',
        (tester) async {
      when(preferences.getString('test')).thenReturn('current value');

      await tester.pumpWidget(
        PreferenceBuilder<String>(
          preference,
          builder: (context, snapshot) {
            return Text(snapshot.data, textDirection: TextDirection.ltr);
          },
        ),
      );

      expect(find.text('current value'), findsOneWidget);
    });

    testWidgets(
        'if current value is null, uses default value for initial build',
        (tester) async {
      when(preferences.getString('test')).thenReturn(null);

      await tester.pumpWidget(
        PreferenceBuilder<String>(
          preference,
          builder: (context, snapshot) {
            return Text(snapshot.data, textDirection: TextDirection.ltr);
          },
        ),
      );

      expect(find.text('default value'), findsOneWidget);
    });

    testWidgets('rebuilds when there is a new value in the Preference stream',
        (tester) async {
      await tester.pumpWidget(
        PreferenceBuilder<String>(
          preference,
          builder: (context, snapshot) {
            return Text(snapshot.data, textDirection: TextDirection.ltr);
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
