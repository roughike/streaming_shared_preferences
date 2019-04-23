import 'dart:async';

/// A platform agnostic contract for storing and retrieving key-value pairs.
///
/// For a [Stream] based implementation that allows reacting to changes, look
/// into [StreamingKeyValueStore].
abstract class KeyValueStore {
  /// Returns all currently stored keys. If no keys exist, returns null.
  Set<String> getKeys();

  /// Returns a previously persisted boolean value for the [key]. If the value is
  /// not a [bool], throws an exception.
  ///
  /// If a value does not exist with the specified [key], returns null.
  bool getBool(String key);

  /// Returns a previously persisted integer value for the [key]. If the value is
  /// not an [int], throws an exception.
  ///
  /// If a value does not exist with the specified [key], returns null.
  int getInt(String key);

  /// Returns a previously persisted double value for the [key]. If the value is
  /// not a [double], throws an exception.
  ///
  /// If a value does not exist with the specified [key], returns null.
  double getDouble(String key);

  /// Returns a previously persisted String value for the [key]. If the value is
  /// not a [String], throws an exception.
  ///
  /// If a value does not exist with the specified [key], returns null.
  String getString(String key);

  /// Returns a previously persisted List<String> value for the [key]. If the value
  /// is not a [List] of [String] elements, throws an exception.
  ///
  /// If a value does not exist with the specified [key], returns null.
  List<String> getStringList(String key);

  /// Persists a boolean [value] in the background and associates it with the
  /// [key].
  ///
  /// Returns a [Future] that completes with a value of `true` if [value] was
  /// successfully persisted.
  Future<bool> setBool(String key, bool value);

  /// Persists an integer [value] in the background and associates it with the
  /// [key].
  ///
  /// Returns a [Future] that completes with a value of `true` if [value] was
  /// successfully persisted.
  Future<bool> setInt(String key, int value);

  /// Persists a double [value] in the background and associates it with the [key].
  ///
  /// Returns a [Future] that completes with a value of `true` if [value] was
  /// successfully persisted.
  Future<bool> setDouble(String key, double value);

  /// Persists a String [value] in the background and associates it with the
  /// [key].
  ///
  /// Returns a [Future] that completes with a value of `true` if [value] was
  /// successfully persisted.
  Future<bool> setString(String key, String value);

  /// Persists a List<String> [value] in the background and associates it with
  /// the [key].
  ///
  /// Returns a [Future] that completes with a value of `true` if [value] was
  /// successfully persisted.
  Future<bool> setStringList(String key, List<String> values);

  /// Removes an entry associated with the specificed [key] from persistent storage.
  ///
  /// Returns a [Future] that completes with a value of `true` if an entry with
  /// the [key] was successfully removed.
  Future<bool> remove(String key);

  /// Removes all entries from persistent storage.
  ///
  /// The [Future] resolves when removing all entries is complete, and returns
  /// `true` if the operation was successful.
  Future<bool> clear();
}
