import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
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
    // This is used in the platform side to register the view.
    var viewType = 'iink_view';

    // Pass parameters to the platform side.
    var creationParams = {
      'type': 'editor_view',
    };
    var messageCodec = StandardMessageCodec();
    var onPlatformViewCreated = (id) {
      this.id = id;
      widget.onCreated(id);
    };

    if (Platform.isAndroid) {
      return PlatformViewLink(
        viewType: viewType,
        surfaceFactory:
            (BuildContext context, PlatformViewController controller) {
          return AndroidViewSurface(
            controller: controller,
            gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{},
            hitTestBehavior: PlatformViewHitTestBehavior.opaque,
          );
        },
        onCreatePlatformView: (PlatformViewCreationParams params) {
          return PlatformViewsService.initSurfaceAndroidView(
            id: params.id,
            viewType: viewType,
            layoutDirection: TextDirection.ltr,
            creationParams: creationParams,
            creationParamsCodec: StandardMessageCodec(),
          )
            ..addOnPlatformViewCreatedListener(params.onPlatformViewCreated)
            ..create();
        },
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
