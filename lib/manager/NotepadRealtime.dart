import 'dart:async';
import 'dart:io';

import 'package:myscript_iink/EditorController.dart';
import 'package:myscript_iink/common.dart';
import 'package:notepad_core/notepad_core.dart';
import 'package:notepad_myscript_demo/HandleMyscript/ConfigMyscriptEngine.dart';
import 'package:notepad_myscript_demo/manager/NotepadManager.dart';
import 'package:notepad_myscript_demo/manager/NotepadUtil.dart';

final sRealtimeManager = RealtimeManager._init();

class RealtimeManager {
  NotepadState _state = sNotepadManager.notepadState;

  FileStruct fileStruct = FileStruct.shared;

  //  正在实时的笔记的第一笔完成，抬笔(up)后触发，一个笔记有且仅会触发一次
  final _firstStrokeStreamController = StreamController<bool>.broadcast();

  Stream<bool> get firstStrokeStreamController =>
      _firstStrokeStreamController.stream;

  var _isHadFristStroke = false;

  bool get isHadFristStroke => _isHadFristStroke;

  firstStrokeEnd(bool value) async {
    if (!_isHadFristStroke && value) _firstStrokeStreamController.add(value);
    _isHadFristStroke = value;
  }

  //  当前书写点类型
  IINKPointerTypeFlutter get pointerType => _prePointer.pointerType;

  //  是否响应实时的点
  var _syncingAvailable = false;

  setPointerType(IINKPointerTypeFlutter value) async {
    _syncingAvailable = false;
    await handleEndCurrentStroke();
    _prePointer = _prePointer.clone(pointerType: value);
    _syncingAvailable = true;
  }

  //  立即结束当前的这一笔
  handleEndCurrentStroke() async {
    if (_prePointer.eventType != IINKPointerEventTypeFlutter.up) {
      await fileStruct.editorController?.syncPointerEvent(
          _prePointer.clone(eventType: IINKPointerEventTypeFlutter.up));
      await firstStrokeEnd(true);
    }
  }

  RealtimeManager._init() {
    print('RealtimeManager._init');
    sNotepadManager.notepadStateStream.listen(_onNotepadStateEvent);
    sNotepadManager.notepadSyncPointerStream.listen(_onSyncPointerEvent);
  }

  start() {
    print('RealtimeManager start');
  }

  //  当前笔属性：颜色、粗细等
  var penStyle = PenStyle.shared;

  setPenStyle(PenStyle value) async {
    if (fileStruct.editorController == null) return;
    await fileStruct.editorController.setPenStyle(value.fromat());
    penStyle = PenStyle.parse(await fileStruct.editorController.getPenStyle());
  }

  //  连接状态处理
  _onNotepadStateEvent(NotepadStateEvent event) async {
    _state = event.state;
    switch (_state) {
      case NotepadState.Connected:
        if (isInitMyscriptSuccess) await intoRealtime();
        break;
      default:
        if (isInitMyscriptSuccess) await finishRealtime();
        break;
    }
  }

  //  处理实时的点
  var _prePointer = IINKPointerEventFlutter.shared;

  _onSyncPointerEvent(NotePenPointer pointer) async {
    if (!isInitMyscriptSuccess) return; // 未初始化引擎
    if (!_syncingAvailable) return; //  相应开关已关闭
    if (fileStruct.editorController == null) return;
    var pe = handlePointerEvent(_prePointer, pointer);
    if (pe == null) return;
    _prePointer = pe;
    await fileStruct.editorController.syncPointerEvent(_prePointer);
    if (_prePointer.eventType == IINKPointerEventTypeFlutter.up) {
      await firstStrokeEnd(true);
    }
  }

  /*
   * 新建一个实时笔记
   */
  Future<void> intoRealtime([FileStruct newFileStruct]) async {
    print('intoRealtime');
    await finishRealtime();

    _syncingAvailable = false;

    await firstStrokeEnd(false);

    _prePointer = IINKPointerEventFlutter.shared;

    if (newFileStruct != null) {
      fileStruct = newFileStruct;
    } else {
      var filePath = await NewFilePath();
      var editorController = await EditorController.create(filePath);
      fileStruct = FileStruct(filePath, editorController);

      penStyle = PenStyle.parse(await fileStruct.editorController.getPenStyle());
      await Future.delayed(Duration(milliseconds: 100), () {});
      (await File(fileStruct.filePath).exists())
          ? await fileStruct.editorController.openPackage(fileStruct.filePath)
          : await fileStruct.editorController.createPackage(fileStruct.filePath);
      await Future.delayed(Duration(milliseconds: 100), () {});
    }

    _syncingAvailable = true;
  }

  /*
   * 结束当前实时
   */
  Future<void> finishRealtime() async {
    print('finishRealtime');
    _syncingAvailable = false;
    await firstStrokeEnd(false);
    await handleEndCurrentStroke();
    if (fileStruct.filePath != '') await fileStruct.editorController?.close();
    _syncingAvailable = true;
  }
}
