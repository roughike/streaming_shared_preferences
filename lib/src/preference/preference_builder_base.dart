import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../streaming_shared_preferences.dart';
import 'preference.dart';

/// A base class for widgets that builds itself based on the latest values of
/// the given [_preferences].
///
/// For examples on how to extend this class, see:
///
/// * [PreferenceBuilder]
/// * [PreferenceBuilder2]
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
    final initialValues =
        widget._preferences.map<T>((p) => p.getValue()).toList();
    _data = initialValues;
    _subscription = _StreamZip<T>(widget._preferences).listen((data) {
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

class _StreamZip<T> extends Stream<List<T>> {
  _StreamZip(this._streams);
  final Iterable<Preference<T>> _streams;

  @override
  StreamSubscription<List<T>> listen(
    void Function(List<T>) onData, {
    Function onError,
    void Function() onDone,
    bool cancelOnError,
  }) {
    cancelOnError = identical(true, cancelOnError);
    var subscriptions = <StreamSubscription<T>>[];
    var controller = StreamController<List<T>>();
    List<T> current;

    void _handleData(int index, T data) {
      current[index] = data;
      final values = List<T>.from(current);
      controller.add(values);
    }

    void _handlePause() {
      for (final subscription in subscriptions) {
        subscription.pause();
      }
    }

    void _handleResume() {
      for (final subscription in subscriptions) {
        subscription.resume();
      }
    }

    void _handleCancel() {
      for (final subscription in subscriptions) {
        subscription.cancel();
      }
    }

    void _handleError(Object error, StackTrace stackTrace) {
      controller.addError(error, stackTrace);
    }

    void _handleErrorCancel(Object error, StackTrace stackTrace) {
      for (var i = 0; i < subscriptions.length; i++) {
        subscriptions[i].cancel();
      }
      controller.addError(error, stackTrace);
    }

    void _handleDone() {
      for (final subscription in subscriptions) {
        subscription.cancel();
      }
      controller.close();
    }

    try {
      for (final preference in _streams) {
        final index = subscriptions.length;
        final stream = preference
            .cast<T>()
            .transform(_EmitOnlyChangedValues<T>(preference));

        subscriptions.add(
          stream.listen(
            (data) => _handleData(index, data),
            onError: cancelOnError ? _handleError : _handleErrorCancel,
            onDone: _handleDone,
            cancelOnError: cancelOnError,
          ),
        );
      }
    } catch (e) {
      for (var i = subscriptions.length - 1; i >= 0; i--) {
        subscriptions[i].cancel();
      }
      rethrow;
    }

    current = List<T>.from(_streams.map((e) => e.getValue()));
    controller
      ..onPause = _handlePause
      ..onResume = _handleResume
      ..onCancel = _handleCancel;

    if (subscriptions.isEmpty) {
      controller.close();
    }

    return controller.stream.listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }
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
