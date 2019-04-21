import 'dart:async';

import 'package:meta/meta.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:streaming_shared_preferences/src/adapters/adapter.dart';
import 'preference.dart';
import 'package:streaming_shared_preferences/src/adapters/primitive_adapters.dart';

/// StreamingSharedPreferences is a reactive version of a [SharedPreferences].
///
/// It wraps [SharedPreferences] with a [Stream] based layer, allowing you to
/// listen to changes in the underlying values. Every `getXYZ()` method returns
/// a [Stream] that doesn't emit anything unless listened to. You can also obtain
/// the current value synchronously by calling `getXYZ().value()`.
///
/// To start using it, await on [StreamingSharedPreferences.instance].
///
/// For example:
///
/// ```
/// final preferences = await StreamingSharedPreferences.instance;
/// ```
///
/// ## Listening to changes in values
///
/// Every method call starting with `get` returns a [Preference]. A [Preference]
/// is a [Stream] that emits updates when there are changes to the underlying value.
///
/// Let's say we are interested in a [String] value with a key "myString":
///
/// ```dart
/// final myString = preferences.getString('myString', defaultsTo: '');
///
/// myString.listen((value) {
///   print(value);
/// });
///
/// /* -- OR: preferences.setString('myString', 'hello world!'); */
/// myString.set('hello world!');
/// ```
///
/// Assuming that the "myString" key is previously unset, the above code will
/// print "", "hello world!" to the console. If "myString" had an existing stored
/// value, it would be the first value the stream emits.
///
/// ## Getting values synchronously
///
/// Streams are great in terms of getting notified about updates. But sometimes
/// you only need to know what the value is right now.
///
/// For that use case, every [Preference] has a method called `value()`:
///
/// ```dart
/// /* -- OR: print(preferences.getString('myString').value()); */
/// print(myString.value());
/// ```
///
/// The above example synchronously retrieves the value of "myString" and prints
/// it to the console.
class StreamingSharedPreferences {
  static Completer<StreamingSharedPreferences> _instanceCompleter;

  /// Private constructor to prevent multiple instances. Creating multiple
  /// instances of the class breaks change detection.
  StreamingSharedPreferences._(this._preferences)
      : _keyChangeController = StreamController<String>.broadcast();

  final SharedPreferences _preferences;
  final StreamController<String> _keyChangeController;

  /// Obtain an instance to a [StreamingSharedPreferences].
  static Future<StreamingSharedPreferences> get instance async {
    if (_instanceCompleter == null) {
      _instanceCompleter = Completer();

      debugObtainSharedPreferencesInstance.then((preferences) {
        final streamingPreferences = StreamingSharedPreferences._(preferences);
        _instanceCompleter.complete(streamingPreferences);
      });
    }

    return _instanceCompleter.future;
  }

  /// Emits all the keys that currently exist - which means keys that have a
  /// non-null value.
  ///
  /// Whenever there's a value associated for a new key, emits all the existing
  /// keys along the newly added key. If a value for a specific key gets removed
  /// (or set to null), emits a set of current keys without the recently removed
  /// key.
  ///
  /// If there are no keys, emits an empty [Set].
  Preference<Set<String>> getKeys() {
    return getCustomValue(
      null,
      defaultsTo: Set(),
      adapter: StringSetAdapter.instance,
    );
  }

  /// Starts with the current bool value for the given [key], then emits a new
  /// value every time there are changes to the value associated with [key].
  ///
  /// If the value is null, starts with the value provided in [defaultsTo].
  Preference<bool> getBool(String key, {@required bool defaultsTo}) {
    return getCustomValue(
      key,
      defaultsTo: defaultsTo,
      adapter: BoolAdapter.instance,
    );
  }

  /// Starts with the current int value for the given [key], then emits a new
  /// value every time there are changes to the value associated with [key].
  ///
  /// If the value is null, starts with the value provided in [defaultsTo].
  Preference<int> getInt(String key, {@required int defaultsTo}) {
    return getCustomValue(
      key,
      defaultsTo: defaultsTo,
      adapter: IntAdapter.instance,
    );
  }

  /// Starts with the current double value for the given [key], then emits a new
  /// value every time there are changes to the value associated with [key].
  ///
  /// If the value is null, starts with the value provided in [defaultsTo].
  Preference<double> getDouble(String key, {@required double defaultsTo}) {
    return getCustomValue(
      key,
      defaultsTo: defaultsTo,
      adapter: DoubleAdapter.instance,
    );
  }

  /// Starts with the current String value for the given [key], then emits a new
  /// value every time there are changes to the value associated with [key].
  ///
  /// If the value is null, starts with the value provided in [defaultsTo].
  Preference<String> getString(String key, {@required String defaultsTo}) {
    return getCustomValue(
      key,
      defaultsTo: defaultsTo,
      adapter: StringAdapter.instance,
    );
  }

  /// Starts with the current String list value for the given [key], then emits
  /// a new value every time there are changes to the value associated with [key].
  ///
  /// If the value is null, starts with the value provided in [defaultsTo].
  Preference<List<String>> getStringList(
    String key, {
    @required List<String> defaultsTo,
  }) {
    return getCustomValue(
      key,
      defaultsTo: defaultsTo,
      adapter: StringListAdapter.instance,
    );
  }

  /// Creates a [Preference] with a custom type. Requires an implementation of
  /// a [PreferenceAdapter].
  ///
  /// Like all other "get()" methods, starts with a current value for the given
  /// [key], then emits a new value every time there are changes to the value
  /// associated with [key].
  ///
  /// Uses an [adapter] for storing and retrieving the custom type from the
  /// persistent storage. For an example of a custom adapter, see the source code
  /// for [getString] and [StringAdapter].
  ///
  /// If the value is null, starts with the value provided in [defaultsTo].
  Preference<T> getCustomValue<T>(
    String key, {
    @required T defaultsTo,
    @required PreferenceAdapter<T> adapter,
  }) {
    assert(adapter != null, 'ValueAdapter must not be null.');
    assert(defaultsTo != null, 'The default value must not be null.');

    return Preference(
      preferences: _preferences,
      key: key,
      defaultValue: defaultsTo,
      adapter: adapter,
      keyChanges: _keyChangeController,
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
  /// Requires an implementation of a [PreferenceAdapter] for the type [T]. For an
  /// example of a custom adapter, see the source code for [setString] and
  /// [StringAdapter].
  ///
  /// Returns true if a [value] was successfully set for the [key], otherwise
  /// returns false.
  Future<bool> setCustomValue<T>(
    String key,
    T value, {
    @required PreferenceAdapter<T> adapter,
  }) {
    assert(key != null, 'key must not be null.');
    assert(adapter != null, 'ValueAdapter must not be null.');

    return _updateAndNotify(key, adapter.set(_preferences, key, value));
  }

  /// Removes the value associated with [key] and notifies all active listeners
  /// that [key] was removed. When a key is removed, the listeners associated
  /// with it will emit their `defaultsTo` value.
  ///
  /// Returns true if [key] was successfully removed, otherwise returns false.
  Future<bool> remove(String key) {
    return _updateAndNotify(key, _preferences.remove(key));
  }

  /// Clears the entire key-value storage by removing all keys and values.
  ///
  /// Notifies all active listeners that their keys got removed, which in turn
  /// makes them emit their respective `defaultsTo` values.
  Future<bool> clear() async {
    final keys = _preferences.getKeys();
    final isSuccessful = await _preferences.clear();
    keys.forEach(_keyChangeController.add);

    return isSuccessful;
  }

  /// Internal helper method for invoking [fn] and capturing the result,
  /// notifying all listeners about an update to [key], and then returning the
  /// previously captured result.
  Future<bool> _updateAndNotify(String key, Future<bool> fn) async {
    final isSuccessful = await fn;
    _keyChangeController.add(key);

    return isSuccessful;
  }
}

/// Used for obtaining an instance of [SharedPreferences] by [MobileKeyValueStore].
///
/// Should not be used outside of tests.
@visibleForTesting
@deprecated
Future<SharedPreferences> debugObtainSharedPreferencesInstance =
    SharedPreferences.getInstance();

/// Resets the singleton instance of [MobileKeyValueStore] so that it can be
/// always tested from a clean slate. Only exists here for testing purposes.
///
/// Should not be called outside of tests.
@visibleForTesting
@deprecated
void debugResetMobileKeyValueStoreInstance() {
  StreamingSharedPreferences._instanceCompleter = null;
}
