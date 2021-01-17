import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'preference.dart';
import 'preference_builder_base.dart';

/// A function that builds a widget whenever a [Preference] has a new value.
typedef PreferenceWidgetBuilder<T> = Function(BuildContext context, T value);

/// A function that builds a widget whenever a [Preference] has a new value.
typedef PreferenceWidgetBuilder2<A, B> = Function(
  BuildContext context,
  A a,
  B b,
);

/// A function that builds a widget whenever a [Preference] has a new value.
typedef PreferenceWidgetBuilder3<A, B, C> = Function(
  BuildContext context,
  A a,
  B b,
  C c,
);

/// A function that builds a widget whenever a [Preference] has a new value.
typedef PreferenceWidgetBuilder4<A, B, C, D> = Function(
  BuildContext context,
  A a,
  B b,
  C c,
  D d,
);

/// A function that builds a widget whenever a [Preference] has a new value.
typedef MultiPreferenceWidgetBuilder = Function(
  BuildContext context,
  List<dynamic> valuess,
);

/// Like a [StreamBuilder] but without the need to provide `initialData`.
///
/// If the preference has a persisted non-null value, the initial build will be
/// done with that value. Otherwise the initial build will be done with the
/// `defaultValue` of the [preference].
///
/// If a [preference] emits a value identical to the last emitted value, [builder]
/// will not be called as it would be unnecessary to do so.
class PreferenceBuilder<T> extends PreferenceBuilderBase<T> {
  PreferenceBuilder({
    @required this.preference,
    @required this.builder,
  })  : assert(preference != null, 'Preference must not be null.'),
        assert(builder != null, 'PreferenceWidgetBuilder must not be null.'),
        super([preference]);

  /// The preference on which you want to react and rebuild your widgets based on.
  final Preference<T> preference;

  /// The function that builds a widget when a [preference] has new data.
  final PreferenceWidgetBuilder<T> builder;

  @override
  Widget build(BuildContext context, List<T> values) {
    assert(values != null);
    assert(values.length == 1);

    return builder(context, values.single);
  }
}

/// Just like [PreferenceBuilder], but supports
class PreferenceBuilder2<A, B> extends PreferenceBuilderBase<dynamic> {
  PreferenceBuilder2(
    this.a,
    this.b, {
    @required this.builder,
  }) : super([a, b]);

  final Preference<A> a;
  final Preference<B> b;
  final PreferenceWidgetBuilder2<A, B> builder;

  @override
  Widget build(BuildContext context, List<dynamic> values) {
    assert(values != null);
    assert(values.length == 2);
    assert(values[0] is A);
    assert(values[1] is B);

    return builder(context, values[0] as A, values[1] as B);
  }
}

class PreferenceBuilder3<A, B, C> extends PreferenceBuilderBase<dynamic> {
  PreferenceBuilder3(
    this.a,
    this.b,
    this.c, {
    @required this.builder,
  }) : super([a, b, c]);

  final Preference<A> a;
  final Preference<B> b;
  final Preference<C> c;
  final PreferenceWidgetBuilder3<A, B, C> builder;

  @override
  Widget build(BuildContext context, List<dynamic> values) {
    assert(values != null);
    assert(values.length == 3);
    assert(values[0] is A);
    assert(values[1] is B);
    assert(values[2] is C);

    return builder(context, values[0] as A, values[1] as B, values[2] as C);
  }
}
