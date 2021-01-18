## 1.1.0
* Add `PreferenceBuilder2` and `PreferenceBuilder3` widgets for watching changes in multiple preferences and rebuilding a widget whenever one of the preferences has a new value
* Add `PreferenceBuilderBase` (from which all preference builders inherit from) to make it easy to implement preference builders for multiple preferences
* Add static analysis, use stronger typing, and generally improve code quality

## 1.0.2
* [#7](https://github.com/roughike/streaming_shared_preferences/pull/7): Loosen constraints on `shared_preferences` dependency
* [#10](https://github.com/roughike/streaming_shared_preferences/pull/10): Add `WidgetsFlutterBinding.ensureInitialize()` to README and example project

## 1.0.1
* [#1](https://github.com/roughike/streaming_shared_preferences/pull/1): Fix a bug where reusing a `Preference` between multiple listeners only propagated the change to the first one

## 1.0.0
* Initial stable release.