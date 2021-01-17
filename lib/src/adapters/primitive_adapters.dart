import 'package:shared_preferences/shared_preferences.dart';

import 'preference_adapter.dart';

/// A [PreferenceAdapter] implementation for storing and retrieving a [bool].
class BoolAdapter extends PreferenceAdapter<bool> {
  const BoolAdapter();

  @override
  bool getValue(SharedPreferences preferences, String key) =>
      preferences.getBool(key);

  @override
  Future<bool> setValue(
    SharedPreferences preferences,
    String key,
    bool value,
  ) =>
      preferences.setBool(key, value);
}

/// A [PreferenceAdapter] implementation for storing and retrieving an [int].
class IntAdapter extends PreferenceAdapter<int> {
  const IntAdapter();

  @override
  int getValue(SharedPreferences preferences, String key) =>
      preferences.getInt(key);

  @override
  Future<bool> setValue(SharedPreferences preferences, String key, int value) =>
      preferences.setInt(key, value);
}

/// A [PreferenceAdapter] implementation for storing and retrieving a [double].
class DoubleAdapter extends PreferenceAdapter<double> {
  const DoubleAdapter();

  @override
  double getValue(SharedPreferences preferences, String key) =>
      preferences.getDouble(key);

  @override
  Future<bool> setValue(
    SharedPreferences preferences,
    String key,
    double value,
  ) =>
      preferences.setDouble(key, value);
}

/// A [PreferenceAdapter] implementation for storing and retrieving a [String].
class StringAdapter extends PreferenceAdapter<String> {
  const StringAdapter();

  @override
  String getValue(SharedPreferences preferences, String key) =>
      preferences.getString(key);

  @override
  Future<bool> setValue(
    SharedPreferences preferences,
    String key,
    String value,
  ) =>
      preferences.setString(key, value);
}

/// A [PreferenceAdapter] implementation for storing and retrieving a [List] of
/// [String] objects.
class StringListAdapter extends PreferenceAdapter<List<String>> {
  const StringListAdapter();

  @override
  List<String> getValue(SharedPreferences preferences, String key) =>
      preferences.getStringList(key);

  @override
  Future<bool> setValue(
    SharedPreferences preferences,
    String key,
    List<String> values,
  ) =>
      preferences.setStringList(key, values);
}
