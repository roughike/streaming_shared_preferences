import 'stored_value_adapter.dart';

/// A [StoredValueAdapter] implementation for storing and retrieving a [bool].
class BoolAdapter extends StoredValueAdapter<bool> {
  static const instance = BoolAdapter._();
  const BoolAdapter._();

  @override
  bool get(keyValueStore, key) => keyValueStore.getBool(key);

  @override
  Future<bool> set(keyValueStore, key, value) => keyValueStore.setBool(key, value);
}

/// A [StoredValueAdapter] implementation for storing and retrieving an [int].
class IntAdapter extends StoredValueAdapter<int> {
  static const instance = IntAdapter._();
  const IntAdapter._();

  @override
  int get(keyValueStore, key) => keyValueStore.getInt(key);

  @override
  Future<bool> set(keyValueStore, key, value) => keyValueStore.setInt(key, value);
}

/// A [StoredValueAdapter] implementation for storing and retrieving a [double].
class DoubleAdapter extends StoredValueAdapter<double> {
  static const instance = DoubleAdapter._();
  const DoubleAdapter._();

  @override
  double get(keyValueStore, key) => keyValueStore.getDouble(key);

  @override
  Future<bool> set(keyValueStore, key, value) =>
      keyValueStore.setDouble(key, value);
}

/// A [StoredValueAdapter] implementation for storing and retrieving a [String].
class StringAdapter extends StoredValueAdapter<String> {
  static const instance = StringAdapter._();
  const StringAdapter._();

  @override
  String get(keyValueStore, key) => keyValueStore.getString(key);

  @override
  Future<bool> set(keyValueStore, key, value) =>
      keyValueStore.setString(key, value);
}

/// A [StoredValueAdapter] implementation for storing and retrieving a [List] of
/// [String] objects.
class StringListAdapter extends StoredValueAdapter<List<String>> {
  static const instance = StringListAdapter._();
  const StringListAdapter._();

  @override
  List<String> get(keyValueStore, key) => keyValueStore.getStringList(key);

  @override
  Future<bool> set(keyValueStore, key, values) =>
      keyValueStore.setStringList(key, values);
}
