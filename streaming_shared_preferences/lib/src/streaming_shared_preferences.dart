import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streaming_key_value_store/streaming_key_value_store.dart';

/// StreamingSharedPreferences is a reactive version of a [SharedPreferences].
///
/// It wraps [SharedPreferences] with a [Stream] based layer, allowing you to
/// listen to changes in the underlying values.
///
/// Every `getXYZ()` method returns a [Stream] that emits values whenever the
/// underlying value updates. You can also obtain the current value synchronously
/// by calling `getXYZ().value()`.
///
/// For more documentation, see the Dart docs on [StreamingKeyValueStore].
class StreamingSharedPreferences extends StreamingKeyValueStore {
  static Completer<StreamingSharedPreferences> _instanceCompleter;

  /// Private constructor to prevent multiple instances. Creating multiple
  /// instances of the class breaks change detection.
  StreamingSharedPreferences._(KeyValueStore keyValueStore)
      : super(keyValueStore);

  /// Obtain an instance to [StreamingSharedPreferences].
  ///
  /// Since  the change detection is tracked by [StreamingKeyValueStore] in Dart
  /// side, multiple instances of a [StreamingSharedPreferences] will not know
  /// about each others changes.
  static Future<StreamingSharedPreferences> get instance async {
    if (_instanceCompleter == null) {
      _instanceCompleter = Completer();

      debugObtainSharedPreferencesInstance.then((preferences) {
        final keyValueStore = SharedPreferencesKeyValueStore(preferences);
        final streamingPrefs = StreamingSharedPreferences._(keyValueStore);
        _instanceCompleter.complete(streamingPrefs);
      });
    }

    return _instanceCompleter.future;
  }
}

/// A [KeyValueStore] implementation that works for Flutter apps.
///
/// Used the shared_preferences plugin as the backing implementation, which in
/// turn uses SharedPreferences on Android and NSUserDefaults on iOS.
///
/// Only exposed for testing purposes.
@visibleForTesting
class SharedPreferencesKeyValueStore implements KeyValueStore {
  SharedPreferencesKeyValueStore(this._preferences);
  final SharedPreferences _preferences;

  /// Returns all currently stored keys. If no keys exist, returns null.
  @override
  Set<String> getKeys() {
    final keys = _preferences.getKeys();
    return keys != null && keys.isNotEmpty ? keys : null;
  }

  /// Returns a previously persisted boolean value for the [key]. If the value is
  /// not a [bool], throws an exception.
  ///
  /// If a value does not exist with the specified [key], returns null.
  @override
  bool getBool(String key) => _preferences.getBool(key);

  /// Returns a previously persisted integer value for the [key]. If the value is
  /// not an [int], throws an exception.
  ///
  /// If a value does not exist with the specified [key], returns null.
  @override
  int getInt(String key) => _preferences.getInt(key);

  /// Returns a previously persisted double value for the [key]. If the value is
  /// not a [double], throws an exception.
  ///
  /// If a value does not exist with the specified [key], returns null.
  @override
  double getDouble(String key) => _preferences.getDouble(key);

  /// Returns a previously persisted String value for the [key]. If the value is
  /// not a [String], throws an exception.
  ///
  /// If a value does not exist with the specified [key], returns null.
  @override
  String getString(String key) => _preferences.getString(key);

  /// Returns a previously persisted List<String> value for the [key]. If the value
  /// is not a [List] of [String] elements, throws an exception.
  ///
  /// If a value does not exist with the specified [key], returns null.
  @override
  List<String> getStringList(String key) => _preferences.getStringList(key);

  /// Persists a boolean [value] in the background and associates it with the
  /// [key].
  ///
  /// Returns a [Future] that completes with a value of `true` if [value] was
  /// successfully persisted.
  @override
  Future<bool> setBool(String key, bool value) =>
      _preferences.setBool(key, value);

  /// Persists an integer [value] in the background and associates it with the
  /// [key].
  ///
  /// Returns a [Future] that completes with a value of `true` if [value] was
  /// successfully persisted.
  @override
  Future<bool> setInt(String key, int value) => _preferences.setInt(key, value);

  /// Persists a double [value] in the background and associates it with the [key].
  ///
  /// Returns a [Future] that completes with a value of `true` if [value] was
  /// successfully persisted.
  @override
  Future<bool> setDouble(String key, double value) =>
      _preferences.setDouble(key, value);

  /// Persists a String [value] in the background and associates it with the
  /// [key].
  ///
  /// Returns a [Future] that completes with a value of `true` if [value] was
  /// successfully persisted.
  @override
  Future<bool> setString(String key, String value) =>
      _preferences.setString(key, value);

  /// Persists a List<String> [value] in the background and associates it with
  /// the [key].
  ///
  /// Returns a [Future] that completes with a value of `true` if [value] was
  /// successfully persisted.
  @override
  Future<bool> setStringList(String key, List<String> values) =>
      _preferences.setStringList(key, values);

  /// Removes an entry associated with the specificed [key] from persistent storage.
  ///
  /// Returns a [Future] that completes with a value of `true` if an entry with
  /// the [key] was successfully removed.
  @override
  Future<bool> remove(String key) => _preferences.remove(key);

  /// Removes all entries from persistent storage.
  ///
  /// The [Future] resolves when removing all entries is complete, and returns
  /// `true` if the operation was successful.
  @override
  Future<bool> clear() => _preferences.clear();
}

/// Used for obtaining an instance of [SharedPreferences] by [StreamingSharedPreferences].
///
/// Should not be used outside of tests.
@visibleForTesting
Future<SharedPreferences> debugObtainSharedPreferencesInstance =
    SharedPreferences.getInstance();

/// Resets the singleton instance of [StreamingSharedPreferences] so that it can
/// be always tested from a clean slate. Only for testing purposes.
///
/// Should not be called outside of tests.
@visibleForTesting
void debugResetStreamingSharedPreferencesInstance() {
  StreamingSharedPreferences._instanceCompleter = null;
}
