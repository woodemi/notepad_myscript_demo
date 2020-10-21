import 'dart:math';
import 'dart:ui';
import 'dart:async';
import 'dart:io';

import 'package:myscript_iink/DeviceSize.dart';
import 'package:myscript_iink/EditorController.dart';
import 'package:myscript_iink/common.dart';
import 'package:notepad_core/models.dart';
import 'package:path_provider/path_provider.dart';

nowDate() => DateTime.now().millisecondsSinceEpoch;

Future<String> NewFilePath({String fileName}) async {
  var directory = await getApplicationDocumentsDirectory();
  var path = '${directory.path}/${fileName ?? nowDate()}.pts';
  return Future.value(path);
}

class FileStruct {
  String filePath;
  EditorController editorController;

  FileStruct(String filePath, [EditorController editorController])
      : this.filePath = filePath,
        this.editorController = editorController;

  static final shared = FileStruct('');

  FileStruct clone({
    String filePath,
    EditorController editorController,
  }) =>
      FileStruct(
        filePath ?? this.filePath,
        editorController ?? this.editorController,
      );
}

class ImportProgress {
  int memoCount;
  int importedCount;

  ImportProgress clone({
    int memoCount,
    int importCount,
  }) =>
      ImportProgress.internal(
        memoCount ?? this.memoCount,
        importCount ?? this.importedCount,
      );

  ImportProgress.internal(int memoCount, int importCount) {
    this.memoCount = memoCount;
    this.importedCount = importCount;
  }
}

enum NotepadState {
  Disconnected,
  Connecting,
  AwaitConfirm,
  Connected,
}

class NotepadStateEvent {
  NotepadState state;
  String cause;

  NotepadStateEvent(NotepadState state, [String cause])
      : this.state = state,
        this.cause = cause;

  factory NotepadStateEvent.fromMap(map) {
    switch (map['state']) {
      case 'Connecting':
        return NotepadStateEvent(NotepadState.Connecting);
      case 'AwaitConfirm':
        return NotepadStateEvent(NotepadState.AwaitConfirm);
      case 'Connected':
        return NotepadStateEvent(NotepadState.Connected);
      default:
        return NotepadStateEvent(NotepadState.Disconnected, map['cause']);
    }
  }
}

IINKPointerEventFlutter handlePointerEvent(
  IINKPointerEventFlutter prePointerEventFlutter,
  NotePenPointer pointer,
) {
  var x = pointer.x.toDouble();
  var y = pointer.y.toDouble();
  var p = pointer.p.toDouble();
  var t = pointer.t.toInt();

  var _preEventType = prePointerEventFlutter.eventType;
  var _pointType = prePointerEventFlutter.pointerType;

  //  第一笔的第一点压感需大于0
  if (_preEventType == IINKPointerEventTypeFlutter.up && p == 0) return null;

  //  越界点-过滤
  var contains = Rect.fromLTWH(
    0,
    0,
    devicePixels.width,
    devicePixels.height,
  ).contains(Offset(x, y));

  if (!contains) {
    // 超界
    if (_preEventType == IINKPointerEventTypeFlutter.up) return null;
    // 贴边返回
    final containX = max(0, min(x, devicePixels.width));
    final containY = max(0, min(y, devicePixels.height));
    return IINKPointerEventFlutter(
      eventType: IINKPointerEventTypeFlutter.up,
      x: containX * viewScale,
      y: containY * viewScale,
      t: t,
      f: p / 512.0,
      pointerType: IINKPointerTypeFlutter.pen,
      pointerId: -1,
    );
  }

  //  获取eventType
  var eventType = (IINKPointerEventTypeFlutter preType, double pressure) {
    switch (preType) {
      case IINKPointerEventTypeFlutter.down:
      case IINKPointerEventTypeFlutter.move:
        return pressure > 0
            ? IINKPointerEventTypeFlutter.move
            : IINKPointerEventTypeFlutter.up;
      case IINKPointerEventTypeFlutter.up:
        return pressure > 0 ? IINKPointerEventTypeFlutter.down : null;
      default:
        return null;
    }
  }(_preEventType, p);

  if (eventType == null) return null;

  return IINKPointerEventFlutter(
    eventType: eventType,
    x: x * viewScale,
    y: y * viewScale,
    t: t,
    f: p / 512.0,
    pointerType: _pointType,
    pointerId: -1,
  );
}

List<IINKPointerEventFlutter> formatPointerEvents(
    List<NotePenPointer> pointers) {
  var pointerEvents = List<IINKPointerEventFlutter>();

  var _prePointer = IINKPointerEventFlutter.shared;
  for (var pointer in pointers) {
    var pe = handlePointerEvent(_prePointer, pointer);
    if (pe != null) {
      pointerEvents.add(pe);
      _prePointer = pe;
    }
  }

  if (pointerEvents.length > 0 &&
      pointerEvents.last.eventType != IINKPointerEventTypeFlutter.up) {
    pointerEvents.add(pointerEvents.last
        .clone(eventType: IINKPointerEventTypeFlutter.up, f: 0));
  }
  return pointerEvents;
}

handleImportMemoData(MemoData memoData) async {
  print('handleImportMemoData');
  var pointerEvents = formatPointerEvents(memoData.pointers);

  //  2000年前的笔记，证明设备未校准时间，按当前时间存储(设备m级，笔记ms级)
  var createdAt = memoData.memoInfo.createdAt * 1000;
  var dateOf2000 = DateTime.utc(2000).millisecondsSinceEpoch;
  var calibrationCreatedAt = createdAt > dateOf2000 ? createdAt : nowDate();

  await handlePointerEvents('$calibrationCreatedAt', pointerEvents);
}

handlePointerEvents(
  String fileName,
  List<IINKPointerEventFlutter> pointerEvents,
) async {
  print('handlePointerEvents');
  if (pointerEvents.length > 0) {
    var path = await NewFilePath(fileName: fileName);
    var importEditorController = await EditorController.create(path);
    (await File(path).exists())
        ? await importEditorController.openPackage(path)
        : await importEditorController.createPackage(path);
    await importEditorController.syncPointerEvents(pointerEvents);
    await importEditorController.close();
  }
}
