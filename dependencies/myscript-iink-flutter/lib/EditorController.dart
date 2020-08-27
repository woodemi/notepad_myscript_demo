import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/services.dart';

import 'DeviceSize.dart';
import 'common.dart';
import 'myscript_iink.dart';

class EditorController {
  MethodChannel _methodChannel;

  EditorController._();

  static Future<EditorController> create(String channelName) async {
    print('createChannel:${channelName}');
    await MyscriptIink.createEditorControllerChannel(channelName);
    final editorController = EditorController._();
    editorController._methodChannel = MethodChannel(channelName);
    await editorController._initRenderEditor();
    await editorController.setPenStyle(PenStyle.shared.fromat());
    return editorController;
  }

  //  close后将完全不可用，关闭通道及释放原生所有对象
  Future<void> close() async {
    if (_methodChannel == null) return;
    print('closeChannel:${_methodChannel.name}');
    await MyscriptIink.closeEditorControllerChannel(_methodChannel.name);
    _methodChannel = null;
  }

  Future<void> _initRenderEditor() async {
    await _methodChannel.invokeMethod(
      'initRenderEditor',
      {
        'viewScale': viewScale,
        'DpiX': Renderer_xDpi,
        'DpiY': Renderer_yDpi,
      },
    );
  }

  Future<void> createPackage(String path) async {
    await _methodChannel.invokeMethod('createPackage', {'path': path});
  }

  Future<void> openPackage(String path) async {
    await _methodChannel.invokeMethod('openPackage', {'path': path});
  }

  Future<void> bindPlatformView(int id) async {
    await _methodChannel.invokeMethod('bindPlatformView', {'id': id});
  }

  Future<void> unbindPlatformView(int id) async {
    await _methodChannel.invokeMethod('unbindPlatformView', {'id': id});
  }

  Future<void> setPenStyle(String penStyle) async {
    await _methodChannel.invokeMethod('setPenStyle', {'penStyle': penStyle});
  }

  Future<String> getPenStyle() async {
    return await _methodChannel.invokeMethod('getPenStyle');
  }

  var _syncStrokeCount = 0;
  Future<void> syncPointerEvent(IINKPointerEventFlutter pointerEvent) async {
    _syncStrokeCount = pointerEvent.eventType == IINKPointerEventTypeFlutter.move
        ? _syncStrokeCount + 1
        : 0;
    if (_syncStrokeCount >= maxStrokeLength) {
      await _methodChannel.invokeMethod(
        'syncPointerEvent',
        pointerEvent.clone(eventType: IINKPointerEventTypeFlutter.up, t: pointerEvent.t + 1).toMap(),
      );
      await _methodChannel.invokeMethod(
        'syncPointerEvent',
        pointerEvent.clone(eventType: IINKPointerEventTypeFlutter.down, t: pointerEvent.t + 2).toMap(),
      );
      _syncStrokeCount = 0;
      print('syncPointerEvent-----------------截取');
    }
    await _methodChannel.invokeMethod('syncPointerEvent', pointerEvent.toMap());
  }

  Future<void> syncPointerEvents(
      List<IINKPointerEventFlutter> pointerEvents) async {
    var list = List<Map<String, dynamic>>();
    var _strokeCount = 0;
    pointerEvents.forEach((pointerEvent) {
      _strokeCount = pointerEvent.eventType == IINKPointerEventTypeFlutter.move
          ? _strokeCount + 1
          : 0;
      if (_strokeCount >= maxStrokeLength) {
        var up = pointerEvent.clone(eventType: IINKPointerEventTypeFlutter.up, t: pointerEvent.t + 1).toMap();
        var down = pointerEvent.clone(eventType: IINKPointerEventTypeFlutter.down, t: pointerEvent.t + 2).toMap();
        list.add(up);
        list.add(down);
        _strokeCount = 0;
        print('syncPointerEvents-----------------截取');
      }
      list.add(pointerEvent.toMap());
    });
    await _methodChannel.invokeMethod('syncPointerEvents', list);
  }

  Future<String> exportText() async {
    try {
      return await _methodChannel.invokeMethod('exportText');
    } catch (e) {
      print('exportText: error = ${e.toString()}');
      return '';
    }
  }

  Future<Uint8List> exportPNG(Uint8List skinBytes) async {
    final bytes = await _methodChannel.invokeMethod(
      'exportPNG',
      {
        //  用于计算物理屏幕比
        'DeviceWidth_mm': DeviceWidth_mm,
        //  计算content相对于skin的x_offset
        'EditArea_xOffsetScale': EditArea_xOffsetScale,
        'skinBytes': skinBytes,
      },
    );
    return bytes;
  }

  Future<Uint8List> exportJPG(Uint8List skinBytes) async {
    final bytes = await _methodChannel.invokeMethod(
      'exportJPG',
      {
        //  用于计算物理屏幕比
        'DeviceWidth_mm': DeviceWidth_mm,
        //  计算content相对于skin的x_offset
        'EditArea_xOffsetScale': EditArea_xOffsetScale,
        'skinBytes': skinBytes,
      },
    );
    return bytes;
  }

  Future<String> exportGIF(Uint8List skinBytes,
      List<IINKPointerEventFlutter> pointerEvents, String gifPath) async {
    var partCount = (pointerEvents.length / 24).toInt();
    var parts = List<List<Map<String, dynamic>>>();
    print('pointerEvents = ${pointerEvents.length}');
    int i = 0;
    do {
      var endIndex = i + partCount < pointerEvents.length - 1
          ? i + partCount
          : pointerEvents.length - 1;
      print(
          'i = $i  endIndex = $endIndex  i <= pointerEvents.length - 1 = ${i <= pointerEvents.length - 1}');
      var tempPS = pointerEvents.sublist(i, endIndex);
      if (tempPS.length > 0) {
        if (tempPS.first.eventType != IINKPointerEventTypeFlutter.down)
          tempPS.insert(0,
              tempPS.first.clone(eventType: IINKPointerEventTypeFlutter.down));
        if (tempPS.last.eventType != IINKPointerEventTypeFlutter.up)
          tempPS.add(
              tempPS.last.clone(eventType: IINKPointerEventTypeFlutter.up));

        var tempMap = List<Map<String, dynamic>>();
        tempPS.forEach((pointerEvent) {
          tempMap.add(pointerEvent.toMap());
        });
        parts.add(tempMap);
      }
      i = endIndex;
    } while (i < pointerEvents.length - 1);

    final gifFilePath = await _methodChannel.invokeMethod('exportGIF', {
      'DeviceWidth_mm': DeviceWidth_mm,
      //  用于计算物理屏幕比
      'EditArea_xOffsetScale': EditArea_xOffsetScale,
      //  计算content相对于skin的x_offset
      'skinBytes': skinBytes,
      'parts': parts,
      'gifPath': gifPath,
    });
    return gifFilePath;
  }

  Future<String> exportJIIX() async {
    try {
      return await _methodChannel.invokeMethod('exportJIIX');
    } catch (e) {
      print('exportJIIX: error = ${e.toString()}');
      return '';
    }
  }

  Future<List<IINKPointerEventFlutter>> parseJIIX(String jiix) async {
    var pointerEvents = List<IINKPointerEventFlutter>();
    if (jiix == null) {
      print('parseJIIX error: jiix = null');
      return pointerEvents;
    }

    var map = jsonDecode(jiix);

    var words = map['words'];
    if (words == null) {
      print('parseJIIX error: words = null');
      return pointerEvents;
    }

    var wordList = (words as List).map((e) => Word.fromMap(e));

    var strokes = List<Stroke>() ;
    for (final word in wordList) strokes.addAll(word.strokes);
    strokes.sort((left, right) => left.pointers[0].t - right.pointers[0].t);
    for (final stroke in strokes) pointerEvents.addAll(stroke.pointers);
    
    return pointerEvents;
  }

  Future<void> clear() async {
    return await _methodChannel.invokeMethod('clear');
  }

  Future<bool>canUndo() async {
    return await _methodChannel.invokeMethod('canUndo');
  }

  Future<bool>undo() async {
    return await _methodChannel.invokeMethod('undo');
  }

  Future<bool>canRedo() async {
    return await _methodChannel.invokeMethod('canRedo');
  }

  Future<bool>redo() async {
    return await _methodChannel.invokeMethod('redo');
  }
}
