# streaming_shared_preferences

[![pub package](https://img.shields.io/pub/v/streaming_shared_preferences.svg)](https://pub.dartlang.org/packages/streaming_shared_preferences)
 [![Build Status](https://travis-ci.org/roughike/streaming_shared_preferences.svg?branch=master)](https://travis-ci.org/roughike/streaming_shared_preferences) 
 [![Coverage Status](https://coveralls.io/repos/github/roughike/streaming_shared_preferences/badge.svg?branch=master)](https://coveralls.io/github/roughike/streaming_shared_preferences?branch=master)

A reactive key-value store for Flutter projects.

**streaming_shared_preferences** adds reactive functionality on top of [shared_preferences](https://pub.dartlang.org/packages/shared_preferences). It does everything that regular `SharedPreferences` does, but it also allows _listening to changes in values_. This makes it super easy to keep your widgets in sync with persisted values.

## Getting started

First, add streaming_shared_preferences into your pubspec.yaml.

If you're already using `shared_preferences`, **you should replace the dependency** with `streaming_shared_preferences`.

```yaml
dependencies:
  streaming_shared_preferences: ^2.0.0
```

To get a hold of `StreamingSharedPreferences`, _await_ on `instance`:

```dart
import 'package:streaming_shared_preferences/streaming_shared_preferences.dart';

...
WidgetsFlutterBinding.ensureInitialized();
final preferences = await StreamingSharedPreferences.instance;
```

**Caveat**: The change detection works only in Dart side.
This means that if you want to react to changes in values, you should always use `StreamingSharedPreferences` (**not** `SharedPreferences`) to store your values.

## Your first streaming preference

Here's the _simplest possible plain Dart example_ on how you would print a value to console every time a `counter` integer changes:

```dart
// Get a reference to the counter value and provide a default value 
// of 0 in case it is null.
Preference<int> counter = preferences.getInt('counter', defaultValue: 0);

// "counter" is a Preference<int> - it can do anything a Stream<int> can.
// We're just going to listen to it and print the value to console.
counter.listen((value) {
  print(value);
});

// Somewhere else in your code, update the value.
counter.setValue(1);

// This is exactly same as above, but the above is more convenient.
preferences.setInt('counter', 2);
```

The public API follows the same convention as regular `SharedPreferences`, but every getter returns a `Preference` object which is a special type of `Stream`.

Assuming that there's no previously stored value (=it's null), the above example will print `0`, `1` and `2` to the console.

### Getting a value synchronously

No problem! Just call `getValue()` on whatever the `preferences.getInt(..)` (or `getString()`, `getBool()`, etc.) returns you.

## Connecting values to Flutter widgets

Althought it works perfectly fine with a `StreamBuilder`, the recommended way is to use the `PreferenceBuilder` widget.

If you have only one value you need to store in your app, it might make sense to listen to it inline:

```dart
class MyCounterWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    /// PreferenceBuilder is like StreamBuilder, but with less boilerplate.
    ///
    /// We don't have to provide `initialData` because it can be fetched synchronously
    /// from the provided Preference. There's also no initial flicker when transitioning
    /// between initialData and the stream.
    ///
    /// If you want, you could use a StreamBuilder too.
    return PreferenceBuilder<int>(
      preference: preferences.getInt('counter', defaultValue: 0),
      builder: (BuildContext context, int counter) {
        return Text('Button pressed $counter times!');
      }
    );
  }
}
```

### Use a wrapper class when having multiple preferences

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

In our app entry point, you'll obtain an instance to `StreamingSharedPreferences` once and pass that to our settings class.
Now we can pass `MyAppSettings` down to the widgets that use it:

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
        PreferenceBuilder<String>(
          preference: settings.nickname,
          builder: (context, nickname) => Text('Hey $nickname!'),
        ),
        PreferenceBuilder<int>(
          preference: settings.counter,
          builder: (context, counter) => Text('You have pushed the button $counter times!'),
        ),
        FloatingActionButton(
          onPressed: () {
            /// To obtain the current value synchronously, we can call ".getValue()".
            final currentCounter = settings.counter.getValue();

            /// To update the value, we can call ".setValue()" - no need to provide a key!
            /// Alternatively, we could just call "preferences.setInt('counter', currentCounter + 1)".
            settings.counter.setValue(currentCounter + 1);
          },
          child: Icon(Icons.add),
        ),
      ],
    );
  }
}
```

You can see a full working example of this [in the example project](https://github.com/roughike/streaming_shared_preferences/blob/master/example/lib/main.dart).

When your widget hierarchy becomes deep enough, you would want to pass `MyAppSettings` around with an [InheritedWidget](https://docs.flutter.io/flutter/widgets/InheritedWidget-class.html) or [provider](https://github.com/rrousselGit/provider) instead.

### "But what about muh abstraction!"

If you're all about the clean architecture and don't want to pollute your domain layer with `Preference` objects from a third-party library by some random internet stranger, all the power to you.

Here's one way to make Uncle Bob proud.

```dart
/// The contract for persistent values in your app that can be shared
/// to your pure business logic classes
abstract class SettingsContract {
  Stream<int> streamCounterValues();
  void setCounter(int value);
}

/// ... somewhere else in your codebase
class MyBusinessLogic {
  MyBusinessLogic(SettingsContract settings) {
    // Do something with "streamCounterValues()" and "setCounter()" along with
    // whatever your business use case needs
  }
}
```

No `StreamingSharedPreferences` specifics went in there.

If for some reason you want to switch into some other library (or get rid of this library altogether), you can do so without modifying your business logic.

Here's how the implementation based on `StreamingSharedPreferences` would look like:

```dart
/// One implementation of SettingsContract backed by StreamingSharedPreferences
class MyAppSettings implements SettingsContract {
  MyAppSettings(StreamingSharedPreferences preferences)
      : counter = preferences.getInt('counter', defaultValue: 0);

  final Preference<int> _counter;

  @override
  Stream<int> streamCounterValues() => _counter;

  @override
  void setCounter(int value) => _counter.setValue(value);
}
```

## Storing custom types with JsonAdapter

The entire library is built to support storing custom data types easily with a `PreferenceAdapter`.
In fact, every built-in type has its own `PreferenceAdapter` - so _every type is actually a custom value_.

For most cases, there's a convenience adapter that handles common pitfalls when storing and retrieving custom values called `JsonAdapter`.
It helps you to store your values in JSON and it also saves you from duplicating `if (value == null) return null` for your custom adapters.

For example, if we have a class called `SampleObject`:

```dart
class SampleObject {
  SampleObject(this.isAwesome);
  final bool isAwesome;

  SampleObject.fromJson(Map<String, dynamic> json) :
    isAwesome = json['isAwesome'];

  Map<String, dynamic> toJson() => { 'isAwesome': isAwesome };
}
```

As seen from the above example, SampleObject implements both `fromJson` and `toJson`.

When the `toJson` method is present, JsonAdapter will call `toJson` automatically. 
For reviving, you need to provide a deserializer that calls `fromJson` manually:

```dart
final sampleObject = preferences.getCustomValue<SampleObject>(
  'my-key',
  defaultValue: SampleObject.empty(),
  adapter: JsonAdapter(
    deserializer: (value) => SampleObject.fromJson(value),
  ),
);
```

Depending on your use case, you need to provide a non-null `SampleObject.empty()` that represents a sane default for your custom type when the value is not loaded just yet.

### Using JsonAdapter with built_value

You can do custom serialization logic before JSON encoding the object by providing a serializer. 
Similarly, you can use deserializer to map the decoded JSON map into any object you want.

For example, if the previous `SampleObject` didn't have `toJson` and `fromJson` methods, but was a built_value model instead:

```dart
final sampleObject = preferences.getCustomValue<SampleObject>(
  'my-key',
  defaultValue: SampleObject.empty(),
  adapter: JsonAdapter(
    serializer: (value) => serializers.serialize(value),
    deserializer: (value) => serializers.deserialize(value),
  ),
);
```

The `serializers` here is your global serializer that comes from `built_value`.
