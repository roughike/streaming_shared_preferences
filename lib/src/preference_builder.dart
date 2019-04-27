import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'preference.dart';

/// A function that returns a rebuilt [Widget] whenever there's a new [value].
typedef PreferenceWidgetBuilder<T> = Widget Function(
  BuildContext context,
  T value,
);

/// Build a widget whenever the [preference] gets updated with a new value.
///
/// The first build will be run with whatever is the default value of [preference].
/// After that, the [builder] function is called with the latest value. The [builder]
/// function will also be called whenever there's a new value.
///
/// Essentially a [StreamBuilder] but without the need to provide `initialData`.
class PreferenceBuilder<T> extends StatefulWidget {
  PreferenceBuilder(
    this.preference, {
    @required this.builder,
  })  : assert(preference != null, 'Preference must not be null.'),
        assert(builder != null, 'PreferenceWidgetBuilder must not be null.');

  /// The preference on which data you want to react and rebuild your widgets
  /// based on.
  final Preference<T> preference;

  /// A function that rebuilds a widget whenever [preference] has a new value.
  final PreferenceWidgetBuilder<T> builder;

  @override
  _PreferenceBuilderState<T> createState() => _PreferenceBuilderState<T>();
}

class _PreferenceBuilderState<T> extends State<PreferenceBuilder<T>> {
  Preference<T> _stream;

  @override
  void initState() {
    super.initState();
    _stream = widget.preference;
  }

  @override
  void didUpdateWidget(PreferenceBuilder<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (kReleaseMode == false) {
      _ensureNotHotSwappingPreferenceObjects(oldWidget, widget);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<T>(
      initialData: _stream.defaultValue,
      stream: _stream,
      builder: (context, snapshot) {
        return widget.builder(context, snapshot.data);
      },
    );
  }
}

/// Throw an error if the initially provided [Preference] changes at any point
/// of time.
void _ensureNotHotSwappingPreferenceObjects(
    PreferenceBuilder oldWidget, PreferenceBuilder newWidget) {
  if (oldWidget.preference != newWidget.preference) {
    final error = PreferenceMismatchError();
    FlutterError.onError(FlutterErrorDetails(exception: error));
  }
}

/// A different [Preference] was passed to a [PreferenceBuilder] than the initial
/// one. This means that a [PreferenceBuilder] is used wrongly and there's a
/// performance issue involved.
class PreferenceMismatchError extends FlutterError {
  PreferenceMismatchError()
      : super(
          'Passed a different Preference instance to a PreferenceBuilder widget '
          'after the first build.\n\n'
          'This usually happens because of creating the Preference instance in the '
          'build method directly, ie. calling PreferenceBuilder(preferences.getXYZ(..)). '
          'This is a performance antipattern because you\'ll end up creating a new '
          'Stream on every rebuild.\n\n'
          'To combat this issue, call preferences.getXYZ() outside of build method, '
          'cache it in a variable, and pass the returned Preference object to your '
          'PreferenceBuilder widget.',
        );
}
