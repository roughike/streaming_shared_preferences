import 'package:flutter/widgets.dart';

import 'preference.dart';

typedef PreferenceWidgetBuilder<T> = Widget Function(
  BuildContext context,
  T value,
);

class PreferenceBuilder<T> extends StatefulWidget {
  PreferenceBuilder(
    this.preference, {
    @required this.builder,
  })  : assert(preference != null, 'Preference must not be null.'),
        assert(builder != null, 'PreferenceWidgetBuilder must not be null.');

  final Preference<T> preference;
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
