import 'package:streaming_key_value_store/src/key_value_store.dart';

/// A [StoredValueAdapter] knows how to retrieve and store a value associated
/// with a key by using a [KeyValueStore].
///
/// For examples, see:
/// * [BoolAdapter], [IntAdapter], [StringAdapter] for simple value adapters
/// * [DateTimeAdapter] and [JsonAdapter] for more involved value adapters
abstract class StoredValueAdapter<T> {
  const StoredValueAdapter();

  /// Retrieve a value associated with the [key] by using the [keyValueStore].
  T get(KeyValueStore keyValueStore, String key);

  /// Set a [value] for the [key] by using the [keyValueStore].
  ///
  /// Returns true if value was successfully set, otherwise false.
  Future<bool> set(KeyValueStore keyValueStore, String key, T value);
}
