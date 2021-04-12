## 2.0.0
* [#16](https://github.com/roughike/streaming_shared_preferences/pull/16): Migrate to null-safety
* [#14](https://github.com/roughike/streaming_shared_preferences/pull/14): Make preference key public

**Breaking changes:**

* As in the null-safe version of [<kbd>shared_preferences</kbd>](https://pub.dev/packages/shared_preferences/changelog#200), setters no longer accept `null` to mean removing values. If you were previously using `set*(key, null)` for removing, use `remove(key)` instead.

## 1.0.2
* [#7](https://github.com/roughike/streaming_shared_preferences/pull/7): Loosen constraints on `shared_preferences` dependency
* [#10](https://github.com/roughike/streaming_shared_preferences/pull/10): Add `WidgetsFlutterBinding.ensureInitialize()` to README and example project

## 1.0.1
* [#1](https://github.com/roughike/streaming_shared_preferences/pull/1): Fix a bug where reusing a `Preference` between multiple listeners only propagated the change to the first one

## 1.0.0
* Initial stable release.
