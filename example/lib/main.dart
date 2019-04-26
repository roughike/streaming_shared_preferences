import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streaming_shared_preferences/streaming_shared_preferences.dart';

/// A class that holds [Preference] objects for the common values that you want
/// to store in your app. This is *not* necessarily needed, but it makes your
/// code more neat.
class MyAppSettings {
  MyAppSettings(StreamingSharedPreferences preferences)
      : counter = preferences.getInt('counter', defaultsTo: 0),
        darkMode = preferences.getBool('darkMode', defaultsTo: false);

  final Preference<int> counter;
  final Preference<bool> darkMode;
}

Future<void> main() async {
  /// Obtain instance to streaming shared preferences, create MyAppSettings, and
  /// once that's done, run the app.
  final preferences = await StreamingSharedPreferences.instance;
  final settings = MyAppSettings(preferences);

  runApp(MyApp(settings));
}

class MyApp extends StatelessWidget {
  MyApp(this.settings);
  final MyAppSettings settings;

  @override
  Widget build(BuildContext context) {
    /// Preference is a Stream, so it can be connected directly into the
    /// StreamBuilder widget. It will emit the latest persisted value which
    /// updates whenever the underlying value changes.
    return StreamBuilder<bool>(
      stream: settings.darkMode,
      builder: (context, AsyncSnapshot<bool> snapshot) {
        final brightness = snapshot.data ? Brightness.dark : Brightness.light;

        return MaterialApp(
          title: 'StreamingSharedPreferences Demo',
          theme: ThemeData(
            primarySwatch: Colors.blue,
            brightness: brightness, // Pass the brightness value here
          ),
          home: MyHomePage(settings),
        );
      },
    );
  }
}

class MyHomePage extends StatelessWidget {
  MyHomePage(this.settings);
  final MyAppSettings settings;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Streaming SharedPreferences'),
        actions: [
          IconButton(
            icon: Icon(Icons.palette),
            onPressed: () {
              /// To obtain the current value synchronously, we call "value()".
              final currentValue = settings.darkMode.value();

              /// Our Preference knows the key it's associated with, so we can
              /// just pass the value. To toggle dark mode, we just invert whatever
              /// the current boolean value is.
              settings.darkMode.set(!currentValue);
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'You have pushed the button this many times:',
            ),

            /// Same as with the "darkMode" boolean - we just connect the value
            /// of "counter" to the UI with a StreamBuilder.
            StreamBuilder<int>(
              stream: settings.counter,
              builder: (context, snapshot) {
                return Text(
                  '${snapshot.data}',
                  style: Theme.of(context).textTheme.display1,
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          /// Same as with setting the "darkMode" boolean - obtain the current
          /// counter value synchronously, then update it.
          final currentValue = settings.counter.value();
          settings.counter.set(currentValue + 1);
        },
        tooltip: 'Increment',
        child: Icon(Icons.add),
      ),
    );
  }
}
