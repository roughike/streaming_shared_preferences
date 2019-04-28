# streaming_shared_preferences - (dev preview)

**(almost ready, going through final testing - for now, use at your own risk)**

[![pub package](https://img.shields.io/pub/v/streaming_shared_preferences.svg)](https://pub.dartlang.org/packages/streaming_shared_preferences)
 [![Build Status](https://travis-ci.org/roughike/streaming_shared_preferences.svg?branch=master)](https://travis-ci.org/roughike/streaming_shared_preferences) 
 [![Coverage Status](https://coveralls.io/repos/github/roughike/streaming_shared_preferences/badge.svg?branch=master)](https://coveralls.io/github/roughike/streaming_shared_preferences?branch=master)

A reactive key-value store for Flutter projects.

It wraps [shared_preferences](https://pub.dartlang.org/packages/shared_preferences) with a reactive `Stream` based layer, allowing you to **listen and react to changes** in the underlying values.

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
// is a little more convenient as there's no need to specify the key.
counter.set(1);
counter.set(2);
counter.set(3);

// Obtain current persisted value synchronously.
final currentValue = counter.value();
```

Assuming that there's no previously stored value for `counter`, the above example will print `0`,
`1`, `2` and `3` to the console.

## Go simple if you don't have a lot of preferences

If you have only one `Preference` in your app, it might make sense to create and listen to a `Preference` inline:

```dart
class MyCounterWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      initialData: 0,
      stream: preferences.getInt('counter', defaultValue: 0),
      builder: (BuildContext context, AsyncSnapshot<int> snapshot) {
       return Text('Button pressed ${snapshot.data} times!');
      }
    );
  }
}
```

## Use a wrapper class when having multiple preferences

If you have multiple preferences, the recommended approach is to create a class that holds all your `Preference` objects in a single place:

```dart
/// A class that holds [Preference] objects for the common values that you want
/// to store in your app. This is *not* necessarily needed, but it makes your
/// code more neat and fool-proof.
class MyAppSettings {
  MyAppSettings(StreamingSharedPreferences preferences)
      : counter = preferences.getInt('counter', defaultValue: 0),
        nickname = preferences.getString('nickname', defaultValue: '');

  final Preference<int> counter;
  final Preference<String> nickname;
}
```

In our app entrypoint, we obtain an instance to `StreamingSharedPreferences` once and pass that to our settings class.
Now we can pass `MyAppSettings` down to the widgets that use it:

```dart
Future<void> main() async {
  /// Obtain instance to streaming shared preferences, create MyAppSettings, and
  /// once that's done, run the app.
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
        StreamBuilder<String>(
          initialData: '',
          stream: settings.nickname,
          builder: (context, snapshot) => Text('Hey ${snapshot.data}!'),
        ),
        StreamBuilder<int>(
          initialData: 0,
          stream: settings.counter,
          builder: (context, snapshot) => Text('You have pushed the button ${snapshot.data} times!'),
        ),
        FloatingActionButton(
          onPressed: () {
            /// To obtain the current value synchronously, we can call ".value()".
            final currentValue = settings.counter.value();

            /// To update the value, we can call ".set()" - no need to provide a key!
            /// Alternatively, we could just call "preferences.setInt('counter', currentValue + 1)".
            settings.counter.set(currentValue + 1);
          },
          child: Icon(Icons.add),
        ),
      ],
    );
  }
}
```

When your widget hierarchy becomes deep enough, you would want to pass `MyAppSettings` around with an [InheritedWidget](https://docs.flutter.io/flutter/widgets/InheritedWidget-class.html) instead.

## "But muh abstraction!"

If you're all about the clean architecture and don't want to pollute your domain layer with `Preference` objects from a third-party library by some random internet stranger, all the power to you.

Here's one way to make Uncle Bob proud.

```dart
/// The contract for persistent values in your app that can be shared
/// to your pure business logic classes
abstract class MyAppSettings {
  Stream<int> getCounter();
  void setCounter(int value);
}

class MyHomePageBloc {
  MyHomePageBloc(this.settings);
  final MyAppSettings settings;

  // Do something with "getCounter()" and "setCounter()" along with 
  // whatever your business use case needs
}
```

No `StreamingSharedPreferences` specifics went in there.
If for some reason you want to switch into some other library (or get rid of this library altogether), you can do so without modifying your business logic.

Here's how the implementation based on `StreamingSharedPreferences` would look like:

```dart
/// One implementation of MyAppSettings backed by StreamingSharedPreferences
class MyStreamingSharedPreferencesSettings implements MyAppSettings {
  MyStreamingSharedPreferences(StreamingSharedPreferences preferences)
      : counter = preferences.getInt('counter', defaultValue: 0);

  final Preference<int> _counter;

  // Preference<int> is a Stream<int>, so we can just return it
  @override
  Stream<int> getCounter() => _counter;

  // Preference exposes a handy "set()" method to update the value
  @override
  void setCounter(int value) => _counter.set(value);
}
```

Not too bad, is it?
It's a good thing `Preference<int>` is also a `Stream<int>` and that there's a handy setter function for every preference.
