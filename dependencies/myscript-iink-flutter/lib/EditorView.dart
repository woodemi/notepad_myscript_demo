import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class EditorView extends StatefulWidget {
  static final TAG = 'editor_view';

  final PlatformViewCreatedCallback onCreated;
  final PlatformViewCreatedCallback onDisposed;

  EditorView({
    @required this.onCreated,
    @required this.onDisposed,
  });

  @override
  State<StatefulWidget> createState() => _EditorViewState();
}

class _EditorViewState extends State<EditorView> {
  int id;

  @override
  void dispose() {
    super.dispose();
    if (id != null) widget.onDisposed(id);
  }

  @override
  Widget build(BuildContext context) {
    var viewType = 'iink_view';
    var creationParams = {
      'type': 'editor_view',
    };
    var messageCodec = StandardMessageCodec();
    var onPlatformViewCreated = (id) {
      this.id = id;
      widget.onCreated(id);
    };

    if (Platform.isAndroid) {
      return AndroidView(
        viewType: viewType,
        creationParams: creationParams,
        creationParamsCodec: messageCodec,
        onPlatformViewCreated: onPlatformViewCreated,
      );
    } else if (Platform.isIOS) {
      return UiKitView(
        viewType: viewType,
        creationParams: creationParams,
        creationParamsCodec: messageCodec,
        onPlatformViewCreated: onPlatformViewCreated,
      );
    }
    return null;
  }
}
