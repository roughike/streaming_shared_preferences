import 'package:streaming_key_value_store/src/key_value_store.dart';
import 'stored_value_adapter.dart';

/// A [StoredValueAdapter] implementation for storing and retrieving a [DateTime].
class DateTimeAdapter extends StoredValueAdapter<DateTime> {
  @override
  DateTime get(KeyValueStore keyValueStore, String key) {
    final value = keyValueStore.getString(key);
    if (value == null) return null;

    return DateTime.fromMillisecondsSinceEpoch(int.parse(value), isUtc: true);
  }

  @override
  Future<bool> set(KeyValueStore keyValueStore, String key, DateTime value) {
    return keyValueStore.setString(
      key,
      value?.millisecondsSinceEpoch?.toString(),
    );
  }
}
