import 'dart:async';
import 'dart:io';

import 'package:myscript_iink/EditorController.dart';
import 'package:myscript_iink/common.dart';
import 'package:notepad_core/notepad_core.dart';
import 'package:notepad_myscript_demo/manager/NotepadManager.dart';
import 'package:notepad_myscript_demo/manager/NotepadUtil.dart';

final sRealtimeManager = RealtimeManager._init();

class RealtimeManager {
  NotepadState _state = sNotepadManager.notepadState;

//  String realtimeFilePath = '';
//
//  EditorController fileStruct.editorController;
  FileStruct fileStruct = FileStruct.shared;

  PenStyle penStyle = PenStyle.shared; //临时使用

  final _firstStrokeStreamController = StreamController<bool>.broadcast();

  Stream<bool> get firstStrokeStreamController =>
      _firstStrokeStreamController.stream;

  var isHadFristStroke = false;

  setHadResetUndoAndRedo(bool value) {
    if (!isHadFristStroke && value) {
      _firstStrokeStreamController.add(true);
    }
    isHadFristStroke = value;
  }

  var isEraser = false;

  setIsEraser(bool value) async {
    _syncingAvailable = false;
    //  结束当前笔、橡皮擦
    if (_prePointer.eventType != IINKPointerEventTypeFlutter.up) {
      await fileStruct.editorController?.syncPointerEvent(
          _prePointer.clone(eventType: IINKPointerEventTypeFlutter.up));
      setHadResetUndoAndRedo(true);
    }
    isEraser = value;
    _syncingAvailable = true;
  }

  RealtimeManager._init() {
    print('RealtimeManager._init');
    sNotepadManager.notepadStateStream.listen(_onNotepadStateEvent);
    sNotepadManager.notepadSyncPointerStream.listen(_onSyncPointerEvent);
  }

  start() {
    print('RealtimeManager start');
  }

  setPenStyle(PenStyle _penStyle) async {
    if (fileStruct.editorController == null) return;
    await fileStruct.editorController.setPenStyle(_penStyle.fromat());
    penStyle = PenStyle.parse(await fileStruct.editorController.getPenStyle());
  }

  _onNotepadStateEvent(NotepadStateEvent event) async {
    _state = event.state;
    switch (_state) {
      case NotepadState.Connected:
        await intoRealtime();
        break;
      default:
        finishRealtime();
        break;
    }
  }

  IINKPointerEventFlutter _prePointer = IINKPointerEventFlutter.shared;

  var _syncingAvailable = false;

  _onSyncPointerEvent(NotePenPointer pointer) async {
    if (!_syncingAvailable) return;
    if (fileStruct.editorController == null) return;
    var pe = handlePointerEvent(_prePointer.eventType, pointer);
    if (isEraser) {
      pe = pe.clone(pointerType: IINKPointerTypeFlutter.eraser);
    }
    if (pe == null) return;
    _prePointer = pe;
    await fileStruct.editorController.syncPointerEvent(_prePointer);
    if (_prePointer.eventType == IINKPointerEventTypeFlutter.up) {
      setHadResetUndoAndRedo(true);
    }
  }

  /*
   * 新建一个实时笔记
   */
  Future<void> intoRealtime([FileStruct newFileStruct]) async {
    print('intoRealtime');
    setHadResetUndoAndRedo(false);
    await finishRealtime();

    if (newFileStruct != null) {
      fileStruct = newFileStruct;
    } else {
      var filePath = await NewFilePath();
      var editorController = await EditorController.create(filePath);
      fileStruct = FileStruct(filePath, editorController);
    }

    penStyle = PenStyle.parse(await fileStruct.editorController.getPenStyle());

    await Future.delayed(Duration(milliseconds: 100), () {});
    (await File(fileStruct.filePath).exists())
        ? await fileStruct.editorController.openPackage(fileStruct.filePath)
        : await fileStruct.editorController.createPackage(fileStruct.filePath);

    await Future.delayed(Duration(milliseconds: 100), () {});

    _syncingAvailable = true;
  }

  /*
   * 结束当前实时
   */
  Future<void> finishRealtime() async {
    print('finishRealtime');
    setHadResetUndoAndRedo(false);
    await setIsEraser(false);
    _syncingAvailable = false;

    if (_prePointer.eventType != IINKPointerEventTypeFlutter.up) {
      final pointerEventFlutter_up =
          _prePointer.clone(eventType: IINKPointerEventTypeFlutter.up);
      await fileStruct.editorController
          ?.syncPointerEvent(pointerEventFlutter_up);
    }

    if (fileStruct.filePath != '') await fileStruct.editorController?.close();

    fileStruct = FileStruct.shared;
    _prePointer = IINKPointerEventFlutter.shared;
  }
}
