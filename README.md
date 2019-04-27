# streaming_shared_preferences - (dev preview)

[![pub package](https://img.shields.io/pub/v/streaming_shared_preferences.svg)](https://pub.dartlang.org/packages/streaming_shared_preferences)
 [![Build Status](https://travis-ci.org/roughike/streaming_shared_preferences.svg?branch=master)](https://travis-ci.org/roughike/streaming_shared_preferences) 
 [![Coverage Status](https://coveralls.io/repos/github/roughike/streaming_shared_preferences/badge.svg)](https://coveralls.io/github/roughike/flutter_facebook_login)

A reactive key-value store for Flutter projects.

It wraps [shared_preferences](https://pub.dartlang.org/packages/shared_preferences) with a reactive `Stream` based layer, allowing you to **listen and react to changes** in the underlying values. <sub><sup>(and it's pure Streams **without rxdart**)</sup></sub>

**For the tl;dr;** look into the [example](example/lib/main.dart) or [read this](#a-real-world-example).

## Simple usage example

To get a hold of `StreamingSharedPreferences`, _await_ on `instance`:

```dart
import 'package:streaming_shared_preferences/streaming_shared_preferences.dart';

...
final preferences = await StreamingSharedPreferences.instance;
```

The public API follows the same naming convention as `shared_preferences` does, but with a little
twist - every getter returns a `Preference` object, which is a special type of `Stream`.

```dart
// Provide a default value of 0 in case "counter" is null.
final counter = preferences.getInt('counter', defaultValue: 0);

// "counter" is a Stream - it can do anything a Stream can!
counter.listen((value) {
  print(value);
});

// You can also call preferences.setInt('counter', <value>) but this
// is a little more convenient.
counter.set(1);
counter.set(2);
counter.set(3);

// Obtain current persisted value synchronously.
final currentValue = counter.value();
```

Assuming that there's no previously stored value for `counter`, the above example will print `0`,
`1`, `2` and `3` to the console.

## Usage with Flutter widgets

Although _you could_ connect `Preference` objects to the UI by calling `preferences.get(..)` and passing that to a `StreamBuilder` widget, that has drawbacks <sub><sup>(more on that below)</sup></sub>.

The recommended approach is to create a class that holds all your `Preference` objects in a single place:

```dart
class MyAppSettings {
  MyAppSettings(StreamingSharedPreferences preferences)
      : counter = preferences.getInt('counter', defaultValue: 0),
        nickname = preferences.getString('nickname', defaultValue: '');

  final Preference<int> counter;
  final Preference<String> nickname;
}
```

In your app entrypoint, you obtain an instance to `StreamingSharedPreferences` once and pass that to your settings class.
Now you can create an instance of `MyAppSettings` once and pass it down to the widgets that use it:

```dart
Future<void> main() async {
  final preferences = await StreamingSharedPreferences.instance;
  final settings = MyAppSettings(preferences);
  
  runApp(MyApp(settings));
}
```

This makes the calling code become quite neat:

```dart
class MyCounterWidget extends StatelessWidget {
  MyCounterWidget(this.settings);
  final MyAppSettings settings;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        PreferenceBuilder<String>(
          settings.nickname,
          builder: (context, nickname) => Text('Hey $nickname!'),
        ),
        PreferenceBuilder<int>(
          settings.counter,
          builder: (context, counter) => Text('You have pushed the button $counter times!'),
        ),
        FloatingActionButton(
          onPressed: () {
            final currentValue = settings.counter.value();
            settings.counter.set(currentValue + 1);
          },
          child: Icon(Icons.add),
        ),
      ],
    );
  }
}
```

When your widget hierarchy becomes deep enough, you would want to pass `MyAppSettings` around with an `InheritedWidget`.

Something like this:

```dart
Future<void> main() async {
  final preferences = await StreamingSharedPreferences.instance;
  final settings = MyAppSettings(preferences);

  runApp(SettingsProvider(
    settings: settings,
    child: MyApp(),
  ));
}
```

Then you'd pass `SettingsProvider.of(context).counter` into a `PreferenceBuilder` or `StreamBuilder`.
