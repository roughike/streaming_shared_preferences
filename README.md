# streaming_shared_preferences - (dev preview)

A reactive key-value store for Flutter projects.

It wraps [shared_preferences](https://pub.dartlang.org/packages/shared_preferences) with a `Stream` based layer, allowing you to **listen to changes** in the underlying values. It serves as a great companion to the [StreamBuilder widget](https://docs.flutter.io/flutter/widgets/StreamBuilder-class.html) or as a reactive data source that you can share between your BLoCs to keep your UI up to date.

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
final counter = preferences.getInt('counter', defaultsTo: 0);

// "counter" is a Stream - it can do anything a Stream can!
counter.listen((value) {
  print(value);
});

// Same as preferences.setInt('counter', <value>), but no need to provide a key here.
counter.set(1);
counter.set(2);
counter.set(3);

// Obtain current value synchronously. In this case, "currentValue" is now 3.
final currentValue = counter.value();
```

Assuming that there's no previously stored value for `counter`, the above example will print `0`,
`1`, `2` and `3` to the console.

## Using StreamingSharedPreferences with the StreamBuilder widget

Here's the standard counter app that you get when creating a Flutter project, but with a twist.

The difference to the regular one is that the value of `counter` is **persisted locally**.
This means that the state will not get lost between app restarts.

```dart
class MyHomePage extends StatefulWidget {
  MyHomePage(this.preferences);
  final StreamingSharedPreferences preferences;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Preference<int> _counter;

  @override
  void initState() {
    super.initState();
    _counter = widget.preferences.getInt('counter', defaultsTo: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('You have pushed the button this many times:'),
        PreferenceBuilder<int>(
          _counter,
          builder: (BuildContext context, int counter) {
            return Text(
              '$counter',
              style: Theme.of(context).textTheme.display1,
            );
          },
        ),
        RaisedButton(
          onPressed: () {
            final currentValue = _counter.value();
            _counter.set(currentValue + 1);
          },
          child: Text('Increment!'),
        ),
      ],
    );
  }
}

```
