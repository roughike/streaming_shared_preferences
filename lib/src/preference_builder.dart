import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'package:streaming_shared_preferences/src/preference.dart';

/// PreferenceBuilder is exactly like a [StreamBuilder] but without the need to
/// provide `initialData`.
///
/// If the preference has a persisted non-null value, the initial build will be
/// done with that value. Otherwise the initial build will be done with the
/// `defaultValue` of the [preference].
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
  final AsyncWidgetBuilder<T> builder;

  @override
  _PreferenceBuilderState<T> createState() => _PreferenceBuilderState<T>();
}

class _PreferenceBuilderState<T> extends State<PreferenceBuilder<T>> {
  T _initialData;
  Stream<T> _preference;

  @override
  void initState() {
    super.initState();
    _initialData = widget.preference.getValue();
    _preference =
        widget.preference.transform(_EmitOnlyChangedValues(_initialData));
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<T>(
      initialData: _initialData,
      stream: _preference,
      builder: widget.builder,
    );
  }
}

/// Makes sure that [PreferenceBuilder] does not run its builder function if
/// there's a new value, but it's identical to the last one.
class _EmitOnlyChangedValues<T> extends StreamTransformerBase<T, T> {
  _EmitOnlyChangedValues(this.startValue);
  final T startValue;

  @override
  Stream<T> bind(Stream<T> stream) {
    return StreamTransformer<T, T>((input, cancelOnError) {
      T lastValue = startValue;

      StreamController<T> controller;
      StreamSubscription<T> subscription;

      controller = StreamController<T>(
        sync: true,
        onListen: () {
          subscription = input.listen(
            (value) {
              if (value != lastValue) {
                controller.add(value);
                lastValue = value;
              }
            },
            onError: controller.addError,
            onDone: controller.close,
            cancelOnError: cancelOnError,
          );
        },
        onPause: ([resumeSignal]) => subscription.pause(resumeSignal),
        onResume: () => subscription.resume(),
        onCancel: () {
          lastValue = null;
          return subscription.cancel();
        },
      );

      return controller.stream.listen(null);
    }).bind(stream);
  }
}
