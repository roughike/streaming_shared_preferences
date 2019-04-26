# streaming_shared_preferences - (dev preview)

[![pub package](https://img.shields.io/pub/v/streaming_shared_preferences.svg)](https://pub.dartlang.org/packages/streaming_shared_preferences)
 [![Build Status](https://travis-ci.org/roughike/streaming_shared_preferences.svg?branch=master)](https://travis-ci.org/roughike/streaming_shared_preferences) 
 [![Coverage Status](https://coveralls.io/repos/github/roughike/streaming_shared_preferences/badge.svg)](https://coveralls.io/github/roughike/flutter_facebook_login)

A reactive key-value store for Flutter projects.

It wraps [shared_preferences](https://pub.dartlang.org/packages/shared_preferences) with a reactive `Stream` based layer, allowing you to **listen to changes** in the underlying values. <sub><sup>(and it's pure Streams **without rxdart**)</sup></sub>

**For the tl;dr;** look into the [example](example/lib/main.dart) or [read this](#a-real-world-example).

## Simple usage example

To get a hold of `StreamingSharedPreferences`, _await_ on `instance`:

```dart
import 'package:streaming_shared_preferences/streaming_shared_preferences.dart';

...
final preferences = await StreamingSharedPreferences.instance;
```

The public API follows the same naming convention as `shared_preferences` does, but with a little
twist - every getter returns a `Preference` object, which is a `Stream`!

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

## Naive (and boilerplatey) example #1: simple usage with StreamBuilder

It's recommended to obtain the instance once in the `main()` method and then pass it down:

```dart
Future<void> main() async {
  final preferences = await StreamingSharedPreferences.instance;

  runApp(MyApp(preferences));
}
```

Since `Preference<int>` is actually a `Stream<int>`, you can pass the `counter` variable to the `StreamBuilder` widget as-is:

```dart
class MyCounterWidget extends StatefulWidget {
  MyCounterWidget(this.preferences);
  final StreamingSharedPreferences preferences;

  @override
  _MyCounterWidgetState createState() => _MyCounterWidgetState();
}

class _MyCounterWidgetState extends State<MyCounterWidget> {
  Preference<int> _counter;

  @override
  void initState() {
    super.initState();
    _counter = widget.preferences.getInt('counter', defaultValue: 0);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      initialValue: 0,
      stream: _counter,
      builder: (BuildContext context, AsyncSnapshot<int> snapshot) {
        return Text('You have pushed the button ${snapshot.data} times!');
      },
    );
  }
}
```

Upon closer inspection, you might notice that it's a little boilerplatey.

We had to provide the fallback value twice - once in `defaultValue` for `Preference` and once in `initialValue` for `StreamBuilder`. On top of that, we had to use a stateful widget in order to avoid creating a stream in the build method.

_"Boilerplate is awesome!"_ - said no one ever.

## Naive example #2: simple usage with PreferenceBuilder

To combat the previous boilerplate, there's a `PreferenceBuilder` widget:

```dart
class MyCounterWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return PreferenceBuilder<int>(
      preferences.getInt('counter', defaultValue: 0),
      builder: (BuildContext context, int value) {
        return Text('You have pushed the button $value times!');
      },
    );
  }
}
```

The `PreferenceBuilder` widget has a couple benefits:

* no need to provide `initialValue` like with `StreamBuilder`
* instead of `AsyncSnapshot<int>`, you get the `int` directly
* you can't shoot yourself on the foot by accidentally recreating and listening to a `Stream` on every rebuild

To be clear, you **don't have to use** `PreferenceBuilder` if you don't want to. 

`StreamBuilder` is completely fine, with one little caveat: do not create `Preference` objects inside the build method by calling `StreamBuilder(stream: preferences.getXYZ(..))`. Doing so will recreate and subscribe to a new `Stream` every time your widget rebuilds. 

If you end up doing so anyway, [you will get nagged a lot](https://github.com/roughike/streaming_shared_preferences/blob/master/lib/src/preference.dart#L164-L223) in debug mode.

## A real world™ example

Everything is so simple in theoretical code samples.

It's highly likely that in a real app you have more values to store, unless your use case actually is clicking on a button that increments a value.
And you'll probably end up with a bunch of other code too, which in turn makes for a lot of vertical code clutter.

Once you start having multiple different settings, it makes sense to wrap them in a custom class:

```dart
class MyAppSettings {
  MyAppSettings(StreamingSharedPreferences preferences)
      : counter = preferences.getInt('counter', defaultValue: 0),
        darkMode = preferences.getBool('darkMode', defaultValue: false),
        nickname = preferences.getString('nickname', defaultValue: '');

  final Preference<int> counter;
  final Preference<bool> darkMode;
  final Preference<String> nickname;
}
```

Now you can create an instance of `MyAppSettings` once, pass it down to the widgets that use it, and the calling code becomes quite neat:

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
