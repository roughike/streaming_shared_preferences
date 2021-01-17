import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streaming_shared_preferences/streaming_shared_preferences.dart';

class MockSharedPreferences extends Mock implements SharedPreferences {}

void main() {
  group('PreferenceBuilder', () {
    MockSharedPreferences preferences;
    StreamController<String> keyChanges;
    TestPreference preference;

    setUp(() {
      preferences = MockSharedPreferences();
      keyChanges = StreamController<String>.broadcast();
      preference = TestPreference(preferences, keyChanges, key: 'test');
    });

    test('passing null Preference throws an error', () {
      expect(
        () => PreferenceBuilder(preference: null, builder: (_, __) => null),
        throwsA(isInstanceOf<AssertionError>()),
      );
    });

    test('passing null PreferenceWidgetBuilder throws an error', () {
      expect(
        () => PreferenceBuilder(preference: preference, builder: null),
        throwsA(isInstanceOf<AssertionError>()),
      );
    });

    testWidgets('initial build is done with current value of the preference',
        (tester) async {
      when(preferences.getString('test')).thenReturn('current value');

      await tester.pumpWidget(
        PreferenceBuilder<String>(
          preference: preference,
          builder: (context, value) {
            return Text(value, textDirection: TextDirection.ltr);
          },
        ),
      );

      expect(find.text('current value'), findsOneWidget);
    });

    group('PreferenceBuilder', () {
      testWidgets(
          'if current value is null, uses default value for initial build',
          (tester) async {
        await tester.pumpWidget(
          PreferenceBuilder<String>(
            preference: preference,
            builder: (context, value) {
              return Text(value, textDirection: TextDirection.ltr);
            },
          ),
        );

        expect(find.text('default value'), findsOneWidget);
      });

      testWidgets('rebuilds when there is a new value in the Preference stream',
          (tester) async {
        await tester.pumpWidget(
          PreferenceBuilder<String>(
            preference: preference,
            builder: (context, value) {
              return Text(value, textDirection: TextDirection.ltr);
            },
          ),
        );

        expect(find.text('default value'), findsOneWidget);

        // Whenever a String with key "test" is retrieved the next time, return
        // the text "updated value".
        when(preferences.getString('test')).thenReturn('updated value');

        // Value does not matter in a test case as the preferences are mocked.
        // This just tells the preference that something was updated.
        preference.setValue(null);
        await tester.pump();
        await tester.pump();
        expect(find.text('updated value'), findsOneWidget);

        when(preferences.getString('test')).thenReturn('another value');
        preference.setValue(null);
        await tester.pump();
        await tester.pump();
        expect(find.text('another value'), findsOneWidget);
      });

      testWidgets(
          'does not rebuild if latest value used for build is identical to new one',
          (tester) async {
        int buildCount = 0;

        await tester.pumpWidget(
          PreferenceBuilder<String>(
            preference: preference,
            builder: (context, value) {
              buildCount++;
              return Text(value, textDirection: TextDirection.ltr);
            },
          ),
        );

        preference.setValue(null);
        await tester.pump();
        await tester.pump();

        preference.setValue(null);
        await tester.pump();
        await tester.pump();

        preference.setValue(null);
        await tester.pump();
        await tester.pump();

        expect(buildCount, 1);

        // So that there's no accidental lockdown because of duplicate values
        when(preferences.getString('test')).thenReturn('new value');
        preference.setValue(null);
        await tester.pump();
        await tester.pump();
        expect(find.text('new value'), findsOneWidget);

        expect(buildCount, 2);
      });

      testWidgets(
          'when the provided preference changes, calls builder with the new value',
          (tester) async {
        const key = ValueKey('text widget');

        when(preferences.getString('test1')).thenReturn('value 1');
        final preference1 =
            TestPreference(preferences, keyChanges, key: 'test1');

        when(preferences.getString('test2')).thenReturn('value 2');
        final preference2 =
            TestPreference(preferences, keyChanges, key: 'test2');

        var useFirstPreference = true;

        await tester.pumpWidget(
          StatefulBuilder(
            builder: (context, setState) {
              return PreferenceBuilder<String>(
                preference: useFirstPreference ? preference1 : preference2,
                builder: (context, value) {
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      setState(() {
                        useFirstPreference = !useFirstPreference;
                      });
                    },
                    child: Text(
                      value,
                      textDirection: TextDirection.ltr,
                      key: key,
                    ),
                  );
                },
              );
            },
          ),
        );

        expect(find.text('value 1'), findsOneWidget);

        // Switch the preference by tapping the text.
        await tester.tap(find.byKey(key));
        await tester.pump();

        expect(find.text('value 2'), findsOneWidget);

        // Switch the preference by tapping the text.
        await tester.tap(find.byKey(key));
        await tester.pump();

        expect(find.text('value 1'), findsOneWidget);
      });

      testWidgets(
          'starts listening to updates in values when the provided preference changes',
          (tester) async {
        const key = ValueKey('text widget');

        when(preferences.getString('test1')).thenReturn('value 1');
        final preference1 =
            TestPreference(preferences, keyChanges, key: 'test1');

        when(preferences.getString('test2')).thenReturn('value 2');
        final preference2 =
            TestPreference(preferences, keyChanges, key: 'test2');

        var useFirstPreference = true;

        await tester.pumpWidget(
          StatefulBuilder(
            builder: (context, setState) {
              return PreferenceBuilder<String>(
                preference: useFirstPreference ? preference1 : preference2,
                builder: (context, value) {
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      setState(() {
                        useFirstPreference = !useFirstPreference;
                      });
                    },
                    child: Text(
                      value,
                      textDirection: TextDirection.ltr,
                      key: key,
                    ),
                  );
                },
              );
            },
          ),
        );

        // Switch the preference by tapping the text.
        await tester.tap(find.byKey(key));
        await tester.pump();

        // Whenever a String with key "test2" is retrieved the next time, return
        // the text "value 2 - updated".
        when(preferences.getString('test2')).thenReturn('value 2 - updated');

        // Value does not matter in a test case as the preferences are mocked.
        // This just tells the preference2 that something was updated.
        preference2.setValue(null);
        await tester.pump();
        await tester.pump();
        expect(find.text('value 2 - updated'), findsOneWidget);

        // Whenever a String with key "test2" is retrieved the next time, return
        // the text "value 2 - updated again".
        when(preferences.getString('test2'))
            .thenReturn('value 2 - updated again');

        // Value does not matter in a test case as the preferences are mocked.
        // This just tells the preference2 that something was updated.
        preference2.setValue(null);
        await tester.pump();
        await tester.pump();
        expect(find.text('value 2 - updated again'), findsOneWidget);

        // Switch the preference by tapping the text.
        await tester.tap(find.byKey(key));
        await tester.pump();

        expect(find.text('value 1'), findsOneWidget);

        // Whenever a String with key "test1" is retrieved the next time, return
        // the text "value 1 - updated".
        when(preferences.getString('test1')).thenReturn('value 1 - updated');

        // Value does not matter in a test case as the preferences are mocked.
        // This just tells the preference1 that something was updated.
        preference1.setValue(null);
        await tester.pump();
        await tester.pump();
        expect(find.text('value 1 - updated'), findsOneWidget);

        // Whenever a String with key "test1" is retrieved the next time, return
        // the text "value 1 - updated again".
        when(preferences.getString('test1'))
            .thenReturn('value 1 - updated again');

        // Value does not matter in a test case as the preferences are mocked.
        // This just tells the preference1 that something was updated.
        preference1.setValue(null);
        await tester.pump();
        await tester.pump();
        expect(find.text('value 1 - updated again'), findsOneWidget);
      });
    });

    group('PreferenceBuilder2', () {
      testWidgets(
          'initial build is done with current values of the preferences',
          (tester) async {
        final preference1 = TestPreference(preferences, keyChanges,
            key: 'one', defaultValue: 'default value 1');
        final preference2 = TestPreference(preferences, keyChanges,
            key: 'two', defaultValue: 'default value 2');

        when(preferences.getString('one')).thenReturn('initial value 1');
        when(preferences.getString('two')).thenReturn('initial value 2');

        await tester.pumpWidget(
          PreferenceBuilder2<String, String>(
            preference1,
            preference2,
            builder: (context, value1, value2) {
              return Text('$value1, $value2', textDirection: TextDirection.ltr);
            },
          ),
        );

        expect(find.text('initial value 1, initial value 2'), findsOneWidget);
      });

      testWidgets(
          'if current values are null, uses default values for initial build',
          (tester) async {
        final preference1 = TestPreference(preferences, keyChanges,
            key: 'one', defaultValue: 'default value 1');
        final preference2 = TestPreference(preferences, keyChanges,
            key: 'two', defaultValue: 'default value 2');

        await tester.pumpWidget(
          PreferenceBuilder2<String, String>(
            preference1,
            preference2,
            builder: (context, value1, value2) {
              return Text('$value1, $value2', textDirection: TextDirection.ltr);
            },
          ),
        );

        expect(
          find.text('default value 1, default value 2'),
          findsOneWidget,
        );
      });

      testWidgets(
          'does not rebuild if latest values used for build are identical to new ones',
          (tester) async {
        final preference1 = TestPreference(preferences, keyChanges,
            key: 'one', defaultValue: 'default value 1');
        final preference2 = TestPreference(preferences, keyChanges,
            key: 'two', defaultValue: 'default value 2');

        int buildCount = 0;

        await tester.pumpWidget(
          PreferenceBuilder2<String, String>(
            preference1,
            preference2,
            builder: (context, value1, value2) {
              buildCount++;
              return Text('$value1, $value2', textDirection: TextDirection.ltr);
            },
          ),
        );

        preference1.setValue(null);
        preference2.setValue(null);
        await tester.pump();
        await tester.pump();

        preference1.setValue(null);
        preference2.setValue(null);
        await tester.pump();
        await tester.pump();

        preference1.setValue(null);
        preference2.setValue(null);
        await tester.pump();
        await tester.pump();

        expect(buildCount, 1);

        // So that there's no accidental lockdown because of duplicate values
        when(preferences.getString('one')).thenReturn('new value 1');
        when(preferences.getString('two')).thenReturn('new value 2');
        preference1.setValue(null);
        preference2.setValue(null);
        await tester.pump();
        await tester.pump();
        expect(find.text('new value 1, new value 2'), findsOneWidget);

        expect(buildCount, 2);
      });
    });

    group('PreferenceBuilder3', () {
      testWidgets(
          'initial build is done with current values of the preferences',
          (tester) async {
        final preference1 = TestPreference(preferences, keyChanges,
            key: 'one', defaultValue: 'default value 1');
        final preference2 = TestPreference(preferences, keyChanges,
            key: 'two', defaultValue: 'default value 2');
        final preference3 = TestPreference(preferences, keyChanges,
            key: 'three', defaultValue: 'default value 3');

        when(preferences.getString('one')).thenReturn('initial value 1');
        when(preferences.getString('two')).thenReturn('initial value 2');
        when(preferences.getString('three')).thenReturn('initial value 3');

        await tester.pumpWidget(
          PreferenceBuilder3<String, String, String>(
            preference1,
            preference2,
            preference3,
            builder: (context, value1, value2, value3) {
              return Text(
                '$value1, $value2, $value3',
                textDirection: TextDirection.ltr,
              );
            },
          ),
        );

        expect(
          find.text('initial value 1, initial value 2, initial value 3'),
          findsOneWidget,
        );
      });

      testWidgets(
          'if current values are null, uses default values for initial build',
          (tester) async {
        final preference1 = TestPreference(preferences, keyChanges,
            key: 'one', defaultValue: 'default value 1');
        final preference2 = TestPreference(preferences, keyChanges,
            key: 'two', defaultValue: 'default value 2');
        final preference3 = TestPreference(preferences, keyChanges,
            key: 'three', defaultValue: 'default value 3');

        await tester.pumpWidget(
          PreferenceBuilder3<String, String, String>(
            preference1,
            preference2,
            preference3,
            builder: (context, value1, value2, value3) {
              return Text(
                '$value1, $value2, $value3',
                textDirection: TextDirection.ltr,
              );
            },
          ),
        );

        expect(
          find.text('default value 1, default value 2, default value 3'),
          findsOneWidget,
        );
      });

      testWidgets(
          'does not rebuild if latest values used for build are identical to new ones',
          (tester) async {
        final preference1 = TestPreference(preferences, keyChanges,
            key: 'one', defaultValue: 'default value 1');
        final preference2 = TestPreference(preferences, keyChanges,
            key: 'two', defaultValue: 'default value 2');
        final preference3 = TestPreference(preferences, keyChanges,
            key: 'three', defaultValue: 'default value 3');

        int buildCount = 0;

        await tester.pumpWidget(
          PreferenceBuilder3<String, String, String>(
            preference1,
            preference2,
            preference3,
            builder: (context, value1, value2, value3) {
              buildCount++;
              return Text(
                '$value1, $value2, $value3',
                textDirection: TextDirection.ltr,
              );
            },
          ),
        );

        preference1.setValue(null);
        preference2.setValue(null);
        preference3.setValue(null);
        await tester.pump();
        await tester.pump();

        preference1.setValue(null);
        preference2.setValue(null);
        preference3.setValue(null);
        await tester.pump();
        await tester.pump();

        preference1.setValue(null);
        preference2.setValue(null);
        preference3.setValue(null);
        await tester.pump();
        await tester.pump();

        expect(buildCount, 1);

        // So that there's no accidental lockdown because of duplicate values
        when(preferences.getString('one')).thenReturn('new value 1');
        when(preferences.getString('two')).thenReturn('new value 2');
        when(preferences.getString('three')).thenReturn('new value 3');
        preference1.setValue(null);
        preference2.setValue(null);
        preference3.setValue(null);
        await tester.pump();
        await tester.pump();
        expect(
          find.text('new value 1, new value 2, new value 3'),
          findsOneWidget,
        );

        expect(buildCount, 2);
      });
    });
  });
}

class TestPreference extends Preference<String> {
  // ignore: non_constant_identifier_names
  TestPreference(
    SharedPreferences preferences,
    StreamController<String> keyChanges, {
    @required String key,
    String defaultValue = 'default value',
  })  : assert(key != null),
        assert(defaultValue != null),
        super.$$_private(
          preferences,
          key,
          defaultValue,
          const StringAdapter(),
          keyChanges,
        );
}
