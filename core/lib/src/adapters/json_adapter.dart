import 'dart:convert';

import 'package:streaming_key_value_store/src/key_value_store.dart';
import 'stored_value_adapter.dart';

/// A convenience adapter that handles common pitfalls when storing and retrieving
/// JSON values.
///
/// [JsonAdapter] eliminates the need for a custom [StoredValueAdapter]. It also
/// saves you from duplicating `if (value == null) return null` custom adapters.
///
/// For example, if we have a class called `SampleObject`:
///
/// ```
/// class SampleObject {
///   SampleObject(this.isAwesome);
///   final bool isAwesome;
///
///   SampleObject.fromJson(Map<String, dynamic> json) :
///     isAwesome = json['isAwesome'];
///
///   Map<String, dynamic> toJson() => { 'isAwesome': isAwesome };
/// }
/// ```
///
/// As seen from the above example, SampleObject implements both `fromJson` and
/// `toJson`.
///
/// When present, [JsonAdapter] will call `toJson` automatically. For reviving,
/// you need to provide a [deserializer] that calls `fromJson` manually:
///
/// ```
/// final sampleObject = keyValueStore.getCustomValue<SampleObject>(
///   'my-key',
///   adapter: JsonAdapter(
///     deserializer: (value) => SampleObject.fromJson(value),
///   ),
/// );
/// ```
///
/// ## Using JsonAdapter with built_value
///
/// You can do custom serialization logic before JSON encoding the object by
/// providing a [serializer]. Similarly, you can use [deserializer] to map the
/// decoded JSON map into any object you want.
///
/// For example:
///
/// ```
/// final sampleObject = keyValueStore.getCustomValue<SampleObject>(
///   'my-key',
///   adapter: JsonAdapter(
///     serializer: (value) => serializers.serialize(value),
///     deserializer: (value) => serializers.deserialize(value),
///   ),
/// );
/// ```
class JsonAdapter<T> extends StoredValueAdapter<T> {
  const JsonAdapter({this.serializer, this.deserializer});
  final Object Function(T) serializer;
  final T Function(Object) deserializer;

  @override
  T get(KeyValueStore keyValueStore, String key) {
    final value = keyValueStore.getString(key);
    if (value == null) return null;

    final decoded = jsonDecode(value);
    return deserializer != null ? deserializer(decoded) : decoded;
  }

  @override
  Future<bool> set(KeyValueStore keyValueStore, String key, T value) {
    final serializedValue = serializer != null ? serializer(value) : value;
    return keyValueStore.setString(key, jsonEncode(serializedValue));
  }
}
