# streaming_shared_preferences - (dev preview)

[![pub package](https://img.shields.io/pub/v/streaming_shared_preferences.svg)](https://pub.dartlang.org/packages/streaming_shared_preferences)
 [![Build Status](https://travis-ci.org/roughike/streaming_shared_preferences.svg?branch=master)](https://travis-ci.org/roughike/streaming_shared_preferences) 
 [![Coverage Status](https://coveralls.io/repos/github/roughike/streaming_shared_preferences/badge.svg)](https://coveralls.io/github/roughike/flutter_facebook_login)

A reactive key-value store for Flutter projects.

It wraps [shared_preferences](https://pub.dartlang.org/packages/shared_preferences) with a reactive `Stream` based layer, allowing you to **listen to changes** in the underlying values. <sub><sup>(and it **does not** depend on rxdart or other unneeded packages!)</sup></sub>

## Simple usage example

To get a hold of `StreamingSharedPreferences`, _await_ on `instance`:

```dart
import 'package:streaming_shared_preferences/streaming_shared_preferences.dart';

...
final preferences = await StreamingSharedPreferences.instance;
```

The public API follows the same naming convention as `shared_preferences` does, but with a little
twist - every getter returns a `Preference` object, which is a `Stream`!

For example, here's how you would get and listen to changes in an `int` with the key "counter":

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

## Naive example #1: usage with StreamBuilder

Since `Preference<int>` is actually a `Stream<int>`, you can pass the `counter` variable to the `StreamBuilder` widget as-is:

```dart
class MyCounterWidget extends StatefulWidget {
  @override
  _MyCounterWidgetState createState() => _MyCounterWidgetState();
}

class _MyCounterWidgetState extends State<MyCounterWidget> {
  Preference<int> _counter;

  @override
  void initState() {
    super.initState();
    _counter = preferences.getInt('counter', defaultValue: 0);
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

That's neat, isn't it? Well, upon closer inspection, you might notice that it's a little boilerplatey.

We had to provide the fallback value twice - once in `defaultValue` for `Preference` and once in `initialValue` for `StreamBuilder`. On top of that, we had to use a `StatefulWidget` in order to avoid creating a `Stream` in the build method. _"Boilerplate is awesome!"_ - said no one ever.

## Naive example #2: usage with PreferenceBuilder

To combat the previous boilerplate, there's a `PreferenceBuilder` widget.

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

However, you **don't have to use** `PreferenceBuilder` if you don't want to. 

`StreamBuilder` is completely fine, with one little caveat: don't create preference objects inside the build method by calling `StreamBuilder(stream: preferences.getXYZ(..))`. Doing so will recreate and subscribe to a new `Stream` every time your widget rebuilds. 

If you end up doing so anyway, [you will get nagged a lot](https://github.com/roughike/streaming_shared_preferences/blob/master/lib/src/preference.dart#L164-L223) in debug mode.
