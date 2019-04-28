import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streaming_shared_preferences/streaming_shared_preferences.dart';

import 'mocks.dart';

void main() {
  group('StreamBuilder and equality tests', () {
    MockSharedPreferences preferences;
    StreamController<String> keyChanges;

    setUp(() {
      preferences = MockSharedPreferences();
      keyChanges = StreamController<String>();
    });

    test('preferences with the same key and type are equal', () {
      expect(
        TestPreference('test', preferences, keyChanges),
        TestPreference('test', preferences, keyChanges),
      );
    });

    test('preferences with same key but different type are not equal', () {
      final first = Preference<String>.$$_private(
        preferences,
        'test',
        'default value',
        StringAdapter.instance,
        keyChanges,
      );

      final second = Preference<int>.$$_private(
        preferences,
        'test',
        0,
        IntAdapter.instance,
        keyChanges,
      );

      expect(first, isNot(equals(second)));
    });

    testWidgets(
        'should listen to the same preference only once even across rebuilds',
        (tester) async {
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (_, stateSetter) {
            return StreamBuilder(
              stream: TestPreference('test', preferences, keyChanges),
              builder: (_, snapshot) {
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

      verify(preferences.getString('test')).called(1);
    });
  });
}

class TestPreference extends Preference<String> {
  // ignore: non_constant_identifier_names
  TestPreference(
    String key,
    SharedPreferences preferences,
    StreamController<String> keyChanges,
  ) : super.$$_private(
          preferences,
          key,
          'default value',
          StringAdapter.instance,
          keyChanges,
        );
}
