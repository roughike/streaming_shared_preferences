import 'dart:async';

import 'package:meta/meta.dart';
import 'package:streaming_key_value_store/src/key_value_store.dart';

import 'adapters/stored_value_adapter.dart';

/// A [StoredValue] is a [Stream] that emits a value whenever the value associated
/// with [key] changes.
///
/// Whenever the backing value associated with [key] transitions from non-null to
/// null, emits [defaultValue]. The [defaultValue] is also emitted initially if
/// the value is null when initially listening to the stream.
///
/// Instead of calling `setXYZ(key, value)` methods on [KeyValueStore], you
/// can store a reference to [StoredValue] and call [set] directly:
///
/// ```dart
/// final myString = keyValueStore.getString('myString', defaultsTo: '');
///
/// myString.set('hello world!');
/// ```
class StoredValue<T> extends StreamView<T> {
  /// Only exposed for testing and internal purposes. Do not call directly in
  /// production code.
  @visibleForTesting
  // ignore: non_constant_identifier_names
  StoredValue.$$_private(this._keyValueStore, this._key, this._defaultValue,
      this._adapter, this._keyChanges)
      : super(_keyChanges.stream.transform(
          _EmitValueChanges(_key, _defaultValue, _adapter, _keyValueStore),
        ));

  /// Get the latest value from the persistent storage synchronously.
  ///
  /// If the returned value doesn't exist (=is null), returns [_defaultValue].
  T value() => _adapter.get(_keyValueStore, _key) ?? _defaultValue;

  /// Update the value and notify all listeners about the new value.
  ///
  /// Returns true if the [value] was successfully set, otherwise returns false.
  Future<bool> set(T value) async {
    if (_key == null) {
      throw UnsupportedError(
        'set() not supported for StoredValue with a null key.',
      );
    }

    return _updateAndNotify(_adapter.set(_keyValueStore, _key, value));
  }

  /// Clear (or in other words, remove) the value. Effectively sets the [_key]
  /// to a null value.
  ///
  /// After removing a value, this [StoredValue] will emit the default value once.
  Future<bool> clear() async {
    if (_key == null) {
      throw UnsupportedError(
        'clear() not supported for StoredValue with a null key.',
      );
    }

    return _updateAndNotify(_keyValueStore.remove(_key));
  }

  /// Invokes [fn] and captures the result, notifies all listeners about an
  /// update to [_key], and then returns the previously captured result.
  Future<bool> _updateAndNotify(Future<bool> fn) async {
    final isSuccessful = await fn;
    _keyChanges.add(_key);

    return isSuccessful;
  }

  // Private fields to not clutter autocompletion results for this class.
  final KeyValueStore _keyValueStore;
  final String _key;
  final T _defaultValue;
  final StoredValueAdapter<T> _adapter;
  final StreamController<String> _keyChanges;
}

/// A [StreamTransformer] that starts with the current persisted value and emits
/// a new one whenever the [key] has update events.
class _EmitValueChanges<T> extends StreamTransformerBase<String, T> {
  _EmitValueChanges(
    this.key,
    this.defaultValue,
    this.valueAdapter,
    this.keyValueStore,
  );

  final String key;
  final T defaultValue;
  final StoredValueAdapter<T> valueAdapter;
  final KeyValueStore keyValueStore;

  T _getValueFromPersistentStorage() {
    // Return the latest value from keyValueStore,
    // If null, returns the default value.
    return valueAdapter.get(keyValueStore, key) ?? defaultValue;
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

          // Track onListen() events for this specific key and throw an error if
          // it seems that a StoredValue is used improperly.
          // _debugTrackOnListenEvent(key, controller);
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
/// `StreamingKeyValueStore`, as in that case there's no specific [key].
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

/*
/// Tracks `onListen()` events and throws a [FlutterError] if a [StoredValue] is
/// listened to too many times in a short time period.
///
/// There is a performance penalty when accidentally recreating (and fetching a
/// persistent value) a [StoredValue] every time a widget is rebuilt. This would
/// commonly happen when accidentally creating a new [StoredValue] by using a
/// `StreamBuilder` widget and passing `keyValueStore.getXYZ()` to it directly.
///
/// Currently throws if there's 4 or more `onListen()` events for the same key
/// in one second.
///
/// Only enabled in debug mode.
void _debugTrackOnListenEvent(String key, StreamController controller) {
  if (!kReleaseMode) {
    if (!debugTrackOnListenEvents) return;

    _keysByLastOnListenTime ??= {};

    final DateTime currentTime = debugObtainCurrentTime();
    final onListenTimes = _keysByLastOnListenTime[key] ?? [];
    onListenTimes.add(currentTime);

    _keysByLastOnListenTime[key] = onListenTimes;

    if (onListenTimes.isNotEmpty) {
      final index = onListenTimes.length - 4;
      final referenceTime = index > -1 ? onListenTimes[index] : null;

      if (referenceTime != null) {
        final difference = currentTime.difference(referenceTime);
        final isTooFast = difference + const Duration(milliseconds: 250) <
            const Duration(seconds: 1);

        if (isTooFast) {
          final error = FlutterError(
            'Called onListen() on a StoredValue with a key "$key" suspiciously '
                'many times on a short time frame.\n\n'
                'This error usually happens because of creating a new StoredValue '
                'multiple times when using the StreamBuilder widget. If you pass '
                'StreamingKeyValueStore.getXYZ() into StreamBuilder directly, '
                'a new instance of a StoredValue is created on every rebuild. '
                'This is highly discouraged, because it will refetch a value from '
                'persistent storage every time the widget rebuilds.\n\n'
                'To combat this issue, cache the value returned by StreamingShared'
                'StoredValues.getXYZ() and pass the returned StoredValue object to your StreamBuilder widget.\n\n'
                'For more information, see the StreamingKeyValueStore '
                'documentation or the README at: https://github.com/roughike/streaming_shared_keyValueStore',
          );

          controller.addError(error);
          FlutterError.onError(FlutterErrorDetails(exception: error));
        }
      }
    }
  }
}

/// Enable or disable throwing errors when a [StoredValue] is listened suspiciously
/// many times in a short time period.
///
/// Only exposed for testing purposes - should not be used in production code.
@visibleForTesting
bool debugTrackOnListenEvents = true;

@visibleForTesting
DateTime Function() debugObtainCurrentTime = () => DateTime.now();

@visibleForTesting
void debugResetOnListenLog() => _keysByLastOnListenTime?.clear();
Map<String, List<DateTime>> _keysByLastOnListenTime;
*/
