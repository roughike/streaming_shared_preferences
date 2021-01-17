import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../streaming_shared_preferences.dart';
import 'preference.dart';

/// A base class for widgets that builds itself based on the latest values of
/// the given [preferences].
///
/// For examples on how to extend this class, see:
///
/// * [PreferenceBuilder]
/// * [PreferenceBuilder2]
abstract class PreferenceBuilderBase<T> extends StatefulWidget {
  const PreferenceBuilderBase({Key key, this.preferences}) : super(key: key);
  final List<Preference<T>> preferences;

  @override
  _PreferenceBuilderBaseState<T> createState() =>
      _PreferenceBuilderBaseState<T>();

  /// Called every time one of the [preferences] emits a new value.
  ///
  /// The [values] contains the latest value of each [Preference] passed to the
  /// list of [preferences]. The [values] will be in the exact same order as
  /// the passed list of [preferences] are.
  Widget build(BuildContext context, List<T> values);
}

class _PreferenceBuilderBaseState<T> extends State<PreferenceBuilderBase<T>> {
  List<T> _data;
  StreamSubscription<List<T>> _subscription;

  @override
  void initState() {
    super.initState();
    _updateStreamSubscription();
  }

  @override
  void didUpdateWidget(PreferenceBuilderBase<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.preferences != widget.preferences) {
      _unsubscribe();
      _updateStreamSubscription();
    }
  }

  @override
  void dispose() {
    _unsubscribe();
    super.dispose();
  }

  void _updateStreamSubscription() {
    final initialValues =
        widget.preferences.map<T>((p) => p.getValue()).toList();
    _data = initialValues;
    _subscription =
        _PreferenceStreamBundle<T>(initialValues, widget.preferences)
            .listen(_handleData);
  }

  void _handleData(List<T> data) {
    if (!mounted) return;

    setState(() {
      _data = data;
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

class _PreferenceStreamBundle<T> extends StreamView<List<T>> {
  _PreferenceStreamBundle(
    Iterable<T> initialValues,
    Iterable<Preference<T>> preferences,
  ) : super(_buildStreamController(initialValues, preferences).stream);

  static StreamController<List<T>> _buildStreamController<T>(
    Iterable<T> initialValues,
    Iterable<Preference<T>> preferences,
  ) {
    final currentValues = List<T>.from(initialValues);
    final subscriptions = <StreamSubscription<T>>[];
    final controller = StreamController<List<T>>(
      onPause: () => subscriptions.forEach(_pause),
      onResume: () => subscriptions.forEach(_resume),
      onCancel: () => subscriptions.forEach(_cancel),
    );

    for (final preference in preferences) {
      final index = subscriptions.length;
      final stream =
          preference.cast<T>().transform(_EmitOnlyChangedValues<T>(preference));

      subscriptions.add(
        stream.listen(
          (data) {
            currentValues[index] = data;
            controller.add(List<T>.from(currentValues));
          },
          onError: controller.addError,
          onDone: () {
            subscriptions.forEach(_cancel);
            controller.close();
          },
        ),
      );
    }

    if (subscriptions.isEmpty) controller.close();
    return controller;
  }

  static void _pause<T>(StreamSubscription<T> subscription) =>
      subscription.pause();
  static void _resume<T>(StreamSubscription<T> subscription) =>
      subscription.resume();
  static void _cancel<T>(StreamSubscription<T> subscription) =>
      subscription.cancel();
}

// Makes sure that [PreferenceBuilder] does not run its builder function if the
// new value is identical to the last one.
class _EmitOnlyChangedValues<T> extends StreamTransformerBase<T, T> {
  const _EmitOnlyChangedValues(this._preference);
  final Preference<T> _preference;

  @override
  Stream<T> bind(Stream<T> stream) {
    return StreamTransformer<T, T>((input, cancelOnError) {
      final initialValue = _preference.getValue();
      T lastValue = initialValue;

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
        onPause: ([Future<void> resumeSignal]) =>
            subscription.pause(resumeSignal),
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
