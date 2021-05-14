import 'package:shared_preferences/shared_preferences.dart';

import 'preference_adapter.dart';

/// A [PreferenceAdapter] implementation for storing and retrieving an enum.
/// 
/// [EnumAdapter] eliminates the need for a custom [PreferenceAdapter]. It also
/// saves you from duplicating `if (value == null) return null` for custom
/// adapters.
///
/// For example, if we have an enum called `SampleEnum`:
///
/// ```
/// enum SampleEnum {
///   valueOne,
///   valueTwo
/// }
/// ```
///
/// We can then create an [EnumAdapter] and use it to receive and store enum values:
///
/// ```
/// final adapter = EnumAdapter<SampleEnum>(
///   values: SampleEnum.values
/// );
/// final sampleEnum = preferences.getCustomValue<SampleEnum>(
///   'my-key',
///   defaultValue: SampleEnum.valueOne,
///   adapter: adapter
/// );
/// ```
class EnumAdapter<T> extends PreferenceAdapter<T> {
  const EnumAdapter({
    required this.values
  });

  final Iterable<T> values;

  @override
  T? getValue(SharedPreferences preferences, String key) {
    final value = preferences.getString(key);

    if (value == null) return null;

    return _enumFromString(value);
  }

  @override
  Future<bool> setValue(SharedPreferences preferences, String key, T value) {
    return preferences.setString(key, _enumToString(value));
  }

  T? _enumFromString(String string) => values.firstWhere((T type) =>
    _enumToString(type) == string,
    orElse: null
  );

  String _enumToString(T value) => value.toString().substring(value.toString().indexOf('.') + 1);
}
