import 'dart:async';

import 'package:meta/meta.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:streaming_shared_preferences/src/adapters/adapter.dart';

/// A [ValueRetriever] is a function that retrieves a value of type of [T] from
/// the persistent storage.
typedef T ValueRetriever<T>();

/// A [ValueSetter] sets a value of type [T] for the predefined key in persistent
/// storage, and returns true or false depending if the operation was successful.
typedef Future<bool> ValueSetter<T>(T value);

/// A [ValueRemover] removes the value from the persistent storage.
typedef Future<bool> ValueRemover();

/// A [Preference] is a [Stream] that emits a value whenever the value associated
/// with [key] changes.
///
/// Whenever the value for [key] is null, emits [defaultValue].
///
/// For example, if an instance of [Preference] is created when the value for
/// [key] is initially null, emits [defaultValue]. Whenever the value gets later
/// set to null, emits the [defaultValue] again.
///
/// Instead of calling `setXYZ(key, value)` methods on [SharedPreferences], you
/// can store a reference to [Preference] and call [set] directly:
///
/// ```dart
/// final myString = preferences.getString('myString', defaultsTo: '');
///
/// myString.set('hello world!');
/// ```
class Preference<T> extends StreamView<T> {
  Preference({
    @required SharedPreferences preferences,
    @required String key,
    @required T defaultValue,
    @required PreferenceAdapter<T> adapter,
    @required StreamController<String> keyChanges,
  })  : value = (() => adapter.get(preferences, key) ?? defaultValue),
        set = ((value) async {
          if (key == null) {
            throw UnsupportedError(
              'set() not supported for Preference with a null key.',
            );
          }

          final result = await adapter.set(preferences, key, value);
          keyChanges.add(key);

          return result;
        }),
        clear = (() async {
          if (key == null) {
            throw UnsupportedError(
              'clear() not supported for Preference with a null key.',
            );
          }

          final result = await preferences.remove(key);
          keyChanges.add(key);

          return result;
        }),
        super(keyChanges.stream.transform(
          _EmitValueChanges(key, defaultValue, adapter, preferences),
        ));

  /// Get the latest value from persistent storage synchronously.
  final ValueRetriever<T> value;

  /// Update the value and notify all listeners about the new value.
  final ValueSetter<T> set;

  /// Clear (=remove) the value.
  ///
  /// After removing a value, [Preference] will emit the default value once.
  final ValueRemover clear;
}

class _EmitValueChanges<T> extends StreamTransformerBase<String, T> {
  _EmitValueChanges(
    this.key,
    this.defaultValue,
    this.valueAdapter,
    this.preferences,
  );

  final String key;
  final T defaultValue;
  final PreferenceAdapter<T> valueAdapter;
  final SharedPreferences preferences;

  T _getValueFromPersistentStorage() {
    // Return the latest value from key-value store.
    // If null, returns the default value.
    return valueAdapter.get(preferences, key) ?? defaultValue;
  }

  @override
  Stream<T> bind(Stream<String> stream) {
    return StreamTransformer<String, T>((input, cancelOnError) {
      StreamController<T> controller;
      StreamSubscription<T> subscription;

      controller = StreamController<T>(
        sync: true,
        onListen: () {
          controller.add(_getValueFromPersistentStorage());

          subscription = input
              .transform(_EmitOnlyMatchingKeys(key))
              .map((_) => _getValueFromPersistentStorage())
              .listen(controller.add, onDone: controller.close);
        },
        onPause: ([resumeSignal]) => subscription.pause(resumeSignal),
        onResume: () => subscription.resume(),
        onCancel: () => subscription.cancel(),
      );

      return controller.stream.listen(null);
    }).bind(stream);
  }
}

class _EmitOnlyMatchingKeys extends StreamTransformerBase<String, String> {
  _EmitOnlyMatchingKeys(this.key);
  final String key;

  @override
  Stream<String> bind(Stream<String> stream) {
    if (key != null) {
      // If key is non-null, emit only the changes that match the key.
      // Otherwise, emit all changes.
      return stream.where((changedKey) => changedKey == key);
    }

    return stream;
  }
}
