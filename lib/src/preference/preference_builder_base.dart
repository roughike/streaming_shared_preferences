import 'dart:async';

import 'package:async/async.dart';
import 'package:flutter/widgets.dart';

import 'preference.dart';

/// A base class for [PreferenceBuilder] widgets.
abstract class PreferenceBuilderBase<T> extends StatefulWidget {
  const PreferenceBuilderBase(this._preferences);
  final List<Preference<T>> _preferences;

  @override
  _PreferenceBuilderBaseState<T> createState() =>
      _PreferenceBuilderBaseState<T>();

  Widget build(BuildContext context, List<T> values);
}

class _PreferenceBuilderBaseState<T> extends State<PreferenceBuilderBase<T>> {
  List<T> _data;
  StreamSubscription<List<T>> _subscription;

  @override
  void initState() {
    super.initState();
    _updateStreams();
  }

  @override
  void didUpdateWidget(PreferenceBuilderBase<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget._preferences != widget._preferences) {
      _unsubscribe();
      _updateStreams();
    }
  }

  @override
  void dispose() {
    _unsubscribe();
    super.dispose();
  }

  void _updateStreams() {
    _data = widget._preferences.map<T>((p) => p.getValue()).toList();
    _subscription = StreamZip<T>(
      widget._preferences.map(
        (p) => p.cast<T>().transform(EmitOnlyChangedValues(p.getValue())),
      ),
    ).listen((data) {
      if (!mounted) return;
      setState(() {
        _data = data;
      });
    });
  }

  void _unsubscribe() {
    if (_subscription != null) {
      _subscription.cancel();
      _subscription = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.build(context, _data);
  }
}

// Makes sure that [PreferenceBuilder] does not run its builder function if the
// new value is identical to the last one.
class EmitOnlyChangedValues<T> extends StreamTransformerBase<T, T> {
  EmitOnlyChangedValues(this.startValue);
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
