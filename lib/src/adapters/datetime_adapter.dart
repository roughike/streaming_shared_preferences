import 'package:shared_preferences/shared_preferences.dart';

import 'preference_adapter.dart';

/// A [PreferenceAdapter] implementation for storing and retrieving a [DateTime].
class DateTimeAdapter extends PreferenceAdapter<DateTime> {
  @override
  DateTime get(SharedPreferences preferences, String key) {
    final value = preferences.getString(key);
    if (value == null) return null;

    return DateTime.fromMillisecondsSinceEpoch(int.parse(value), isUtc: true);
  }

  @override
  Future<bool> set(SharedPreferences preferences, String key, DateTime value) {
    return preferences.setString(
      key,
      value?.millisecondsSinceEpoch?.toString(),
    );
  }
}
