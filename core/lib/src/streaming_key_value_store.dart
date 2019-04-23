import 'dart:async';

import 'package:meta/meta.dart';
import 'package:streaming_key_value_store/src/key_value_store.dart';
import 'package:streaming_key_value_store/src/stored_value.dart';

import 'adapters/adapters.dart';

/// StreamingKeyValueStore is a reactive version of a [KeyValueStore].
///
/// It wraps [KeyValueStore] with a [Stream] based layer, allowing you to
/// listen to changes in the underlying values.
///
/// Every `getXYZ()` method returns a [Stream] that emits values whenever the
/// underlying value updates. You can also obtain the current value synchronously
/// by calling `getXYZ().value()`.
///
/// To start using it, await on [StreamingKeyValueStore.instance].
class StreamingKeyValueStore {
  /// Wraps the provided [keyValueStore] with a reactive, stream-based layer that
  /// allows you to react to changes in underlying values.
  ///
  /// You should not create multiple instances of a [StreamingKeyValueStore]. Since
  /// the change detection is only tracked by this wrapper class, multiple instances
  /// of a [StreamingKeyValueStore] will not know about each others changes.
  StreamingKeyValueStore(this._keyValueStore)
      : _keyChanges = StreamController<String>.broadcast();

  final KeyValueStore _keyValueStore;
  final StreamController<String> _keyChanges;

  /// Emits all the keys that currently exist - which means keys that have a
  /// non-null value.
  ///
  /// Whenever there's a value associated for a new key, emits all the existing
  /// keys along the newly added key. If a value for a specific key gets removed
  /// (or set to null), emits a set of current keys without the recently removed
  /// key.
  ///
  /// If there are no keys, emits an empty [Set].
  StoredValue<Set<String>> getKeys() {
    return _getValueAllowingNullKey(
      null,
      defaultsTo: Set(),
      adapter: _GetKeysAdapter.instance,
    );
  }

  /// Starts with the current bool value for the given [key], then emits a new
  /// value every time there are changes to the value associated with [key].
  ///
  /// If the value is null, starts with the value provided in [defaultsTo]. When
  /// the value transitions from non-null to null (ie. when the value is removed),
  /// emits [defaultsTo].
  StoredValue<bool> getBool(String key, {@required bool defaultsTo}) {
    return getCustomValue(
      key,
      defaultsTo: defaultsTo,
      adapter: BoolAdapter.instance,
    );
  }

  /// Starts with the current int value for the given [key], then emits a new
  /// value every time there are changes to the value associated with [key].
  ///
  /// If the value is null, starts with the value provided in [defaultsTo]. When
  /// the value transitions from non-null to null (ie. when the value is removed),
  /// emits [defaultsTo].
  StoredValue<int> getInt(String key, {@required int defaultsTo}) {
    return getCustomValue(
      key,
      defaultsTo: defaultsTo,
      adapter: IntAdapter.instance,
    );
  }

  /// Starts with the current double value for the given [key], then emits a new
  /// value every time there are changes to the value associated with [key].
  ///
  /// If the value is null, starts with the value provided in [defaultsTo]. When
  /// the value transitions from non-null to null (ie. when the value is removed),
  /// emits [defaultsTo].
  StoredValue<double> getDouble(String key, {@required double defaultsTo}) {
    return getCustomValue(
      key,
      defaultsTo: defaultsTo,
      adapter: DoubleAdapter.instance,
    );
  }

  /// Starts with the current String value for the given [key], then emits a new
  /// value every time there are changes to the value associated with [key].
  ///
  /// If the value is null, starts with the value provided in [defaultsTo]. When
  /// the value transitions from non-null to null (ie. when the value is removed),
  /// emits [defaultsTo].
  StoredValue<String> getString(String key, {@required String defaultsTo}) {
    return getCustomValue(
      key,
      defaultsTo: defaultsTo,
      adapter: StringAdapter.instance,
    );
  }

  /// Starts with the current String list value for the given [key], then emits
  /// a new value every time there are changes to the value associated with [key].
  ///
  /// If the value is null, starts with the value provided in [defaultsTo]. When
  /// the value transitions from non-null to null (ie. when the value is removed),
  /// emits [defaultsTo].
  StoredValue<List<String>> getStringList(
    String key, {
    @required List<String> defaultsTo,
  }) {
    return getCustomValue(
      key,
      defaultsTo: defaultsTo,
      adapter: StringListAdapter.instance,
    );
  }

  /// Creates a [StoredValue] with a custom type. Requires an implementation of
  /// a [StoredValueAdapter].
  ///
  /// Like all other "get()" methods, starts with a current value for the given
  /// [key], then emits a new value every time there are changes to the value
  /// associated with [key].
  ///
  /// Uses an [adapter] for storing and retrieving the custom type from the
  /// persistent storage. For an example of a custom adapter, see the source code
  /// for [getString] and [StringAdapter].
  ///
  /// If the value is null, starts with the value provided in [defaultsTo]. When
  /// the value transitions from non-null to null (ie. when the value is removed),
  /// emits [defaultsTo].
  StoredValue<T> getCustomValue<T>(
    String key, {
    @required T defaultsTo,
    @required StoredValueAdapter<T> adapter,
  }) {
    assert(key != null, 'StoredValue key must not be null.');

    return _getValueAllowingNullKey(
      key,
      defaultsTo: defaultsTo,
      adapter: adapter,
    );
  }

  /// Sets a bool value and notifies all active listeners that there's a new
  /// value for the [key].
  ///
  /// Returns true if a [value] was successfully set for the [key], otherwise
  /// returns false.
  Future<bool> setBool(String key, bool value) {
    return setCustomValue(key, value, adapter: BoolAdapter.instance);
  }

  /// Sets a int value and notifies all active listeners that there's a new
  /// value for the [key].
  ///
  /// Returns true if a [value] was successfully set for the [key], otherwise
  /// returns false.
  Future<bool> setInt(String key, int value) {
    return setCustomValue(key, value, adapter: IntAdapter.instance);
  }

  /// Sets a double value and notifies all active listeners that there's a new
  /// value for the [key].
  ///
  /// Returns true if a [value] was successfully set for the [key], otherwise
  /// returns false.
  Future<bool> setDouble(String key, double value) {
    return setCustomValue(key, value, adapter: DoubleAdapter.instance);
  }

  /// Sets a String value and notifies all active listeners that there's a new
  /// value for the [key].
  ///
  /// Returns true if a [value] was successfully set for the [key], otherwise
  /// returns false.
  Future<bool> setString(String key, String value) {
    return setCustomValue(key, value, adapter: StringAdapter.instance);
  }

  /// Sets a String list value and notifies all active listeners that there's a
  /// new value for the [key].
  ///
  /// Returns true if a [value] was successfully set for the [key], otherwise
  /// returns false.
  Future<bool> setStringList(String key, List<String> values) {
    return setCustomValue(key, values, adapter: StringListAdapter.instance);
  }

  /// Sets a value of custom type [T] and notifies all active listeners that
  /// there's a new value for the [key].
  ///
  /// Requires an implementation of a [StoredValueAdapter] for the type [T]. For an
  /// example of a custom adapter, see the source code for [setString] and
  /// [StringAdapter].
  ///
  /// Returns true if a [value] was successfully set for the [key], otherwise
  /// returns false.
  Future<bool> setCustomValue<T>(
    String key,
    T value, {
    @required StoredValueAdapter<T> adapter,
  }) {
    assert(key != null, 'key must not be null.');
    assert(adapter != null, 'StoredValueAdapter must not be null.');

    return _updateAndNotify(key, adapter.set(_keyValueStore, key, value));
  }

  /// Removes the value associated with [key] and notifies all active listeners
  /// that [key] was removed. When a key is removed, the listeners associated
  /// with it will emit their `defaultsTo` value.
  ///
  /// Returns true if [key] was successfully removed, otherwise returns false.
  Future<bool> remove(String key) {
    return _updateAndNotify(key, _keyValueStore.remove(key));
  }

  /// Clears the entire key-value storage by removing all keys and values.
  ///
  /// Notifies all active listeners that their keys got removed, which in turn
  /// makes them emit their respective `defaultsTo` values.
  Future<bool> clear() async {
    final keys = _keyValueStore.getKeys();
    final isSuccessful = await _keyValueStore.clear();
    keys.forEach(_keyChanges.add);

    return isSuccessful;
  }

  /// Invokes [fn] and captures the result, notifies all listeners about an
  /// update to [key], and then returns the previously captured result.
  Future<bool> _updateAndNotify(String key, Future<bool> fn) async {
    final isSuccessful = await fn;
    _keyChanges.add(key);

    return isSuccessful;
  }

  /// Bypasses the key != null assertion but makes sure [defaultsTo] and [adapter]
  /// are non-null.
  StoredValue<T> _getValueAllowingNullKey<T>(
    String key, {
    @required T defaultsTo,
    @required StoredValueAdapter<T> adapter,
  }) {
    assert(adapter != null, 'StoredValueAdapter must not be null.');
    assert(defaultsTo != null, 'The default value must not be null.');

    // ignore: invalid_use_of_visible_for_testing_member
    return StoredValue.$$_private(
      _keyValueStore,
      key,
      defaultsTo,
      adapter,
      _keyChanges,
    );
  }
}

/// A special [StoredValueAdapter] for getting all currently stored keys. Does not
/// support [set] operations.
class _GetKeysAdapter extends StoredValueAdapter<Set<String>> {
  static const instance = _GetKeysAdapter._();
  const _GetKeysAdapter._();

  @override
  Set<String> get(keyValueStore, _) => keyValueStore.getKeys();

  @override
  Future<bool> set(_, __, ___) =>
      throw UnsupportedError('KeyValueStore.setKeys() is not supported.');
}
