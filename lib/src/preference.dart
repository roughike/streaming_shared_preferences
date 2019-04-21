import 'dart:async';

import 'package:meta/meta.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'adapters/preference_adapter.dart';

/// A [Preference] is a [Stream] that emits a value whenever the value associated
/// with [key] changes.
///
/// Whenever the backing value associated with [key] transitions from non-null to
/// null, emits [defaultValue]. The [defaultValue] is also emitted initially if
/// the value is null when initially listening to the stream.
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
  /// Only exposed for testing and internal purposes. Do not call directly in
  /// production code.
  @deprecated
  @visibleForTesting
  // ignore: non_constant_identifier_names
  Preference.$$_private({
    @required SharedPreferences preferences,
    @required String key,
    @required T defaultValue,
    @required PreferenceAdapter<T> adapter,
    @required StreamController<String> keyChanges,
  })  : _value = (() => adapter.get(preferences, key) ?? defaultValue),
        _set = ((value) async {
          if (key == null) {
            throw UnsupportedError(
              'set() not supported for Preference with a null key.',
            );
          }

          final result = await adapter.set(preferences, key, value);
          keyChanges.add(key);

          return result;
        }),
        _clear = (() async {
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
  T value() => _value();

  /// Update the value and notify all listeners about the new value.
  ///
  /// Returns true if the [value] was successfully set, otherwise returns false.
  Future<bool> set(T value) => _set(value);

  /// Clear (or in other words, remove) the value.
  ///
  /// After removing a value, this [Preference] will emit the default value once.
  Future<bool> clear() => _clear();

  final T Function() _value;
  final Future<bool> Function(T) _set;
  final Future<bool> Function() _clear;
}

/// A [StreamTransformer] that starts with the current persisted value and emits
/// a new one whenever the [key] has update events.
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
    // Return the latest value from preferences,
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
          // When the stream is listened to, start with the current persisted
          // value.
          controller.add(_getValueFromPersistentStorage());

          // Whenever a key has been updated, fetch the current persisted value
          // and emit it.
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

/// A [StreamTransformer] that filters out values that don't match the [key].
///
/// One exception is when the [key] is null - in this case, returns the source
/// stream as is. One such case would be calling the `getKeys()` method on the
/// `StreamingSharedPreferences`, as in that case there's no specific [key].
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
