import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:myscript_iink/EditorController.dart';
import 'package:myscript_iink/EditorView.dart';
import 'package:myscript_iink/DeviceSize.dart';
import 'package:myscript_iink/common.dart';
import 'package:notepad_core/models.dart';
import 'package:notepad_myscript_demo/ConnectDevice/DeviceList.dart';
import 'package:notepad_myscript_demo/ConnectDevice/NotepadDetailPage.dart';
import 'package:notepad_myscript_demo/HandleMyscript/NoteReplayPage.dart';
import 'package:notepad_myscript_demo/util/widgets.dart';
import 'package:notepad_myscript_demo/util/colors.dart';
import 'package:path_provider/path_provider.dart';
import 'package:notepad_myscript_demo/manager/NotepadManager.dart';
import 'package:notepad_myscript_demo/manager/NotepadRealtime.dart';
import 'package:notepad_myscript_demo/manager/NotepadUtil.dart';
import 'package:notepad_myscript_demo/util/FunctionListWidget.dart';

import '../util/Toast.dart';

class IInkViewPage extends StatefulWidget {
  final String filePath;

  IInkViewPage(this.filePath);

  @override
  State<StatefulWidget> createState() => _IInkViewPageState();
}

class _IInkViewPageState extends State<IInkViewPage> {
  //  myscript的方法集
  var myscriptList = List<FunctionItem>();

  EditorController _editorController;

  String penColor;
  PenStyle penStyle;

  var _pointerType = IINKPointerTypeFlutter.pen;

  setIsEraser(bool value) async {
    setState(() {
      _pointerType =
          value ? IINKPointerTypeFlutter.eraser : IINKPointerTypeFlutter.pen;
    });
    if (sRealtimeManager.fileStruct.filePath == widget.filePath) {
      await sRealtimeManager.setPointerType(_pointerType);
    }
  }

  var notepadState = sNotepadManager.notepadState;

  StreamSubscription<NotepadStateEvent> _notepadStateSubscription;

  //  是否可以撤销/前进
  StreamSubscription<bool> _firstStrokeSubscription;

  var canUndo = false;
  var canRedo = false;

  firstStroke(bool value) async {
    if (value) await resetUndoAndRedo();
  }

  resetUndoAndRedo() async {
    var _canUndo = await _editorController.canUndo();
    var _canRedo = await _editorController.canRedo();
    print('_canUndo = $_canUndo');
    print('_canRedo = $_canRedo');
    setState(() {
      canUndo = _canUndo;
      canRedo = _canRedo;
    });
  }

  @override
  void initState() {
    super.initState();
    initFunctionList();

    _notepadStateSubscription =
        sNotepadManager.notepadStateStream.listen(_onNotepadStateEvent);
    _firstStrokeSubscription =
        sRealtimeManager.firstStrokeStreamController.listen(firstStroke);
  }

  @override
  void dispose() {
    super.dispose();
    _notepadStateSubscription.cancel();
    _notepadStateSubscription = null;
    _firstStrokeSubscription.cancel();
    _firstStrokeSubscription = null;
  }

  initEditorController() async {
    print('widget.filePath = ${widget.filePath}');
    if (sRealtimeManager.fileStruct.filePath == widget.filePath) {
      _editorController = sRealtimeManager.fileStruct.editorController;
      _pointerType = sRealtimeManager.pointerType;
    } else {
      _editorController = await EditorController.create(widget.filePath);
      (await File(widget.filePath).exists())
          ? await _editorController.openPackage(widget.filePath)
          : await _editorController.createPackage(widget.filePath);
      var value = await _editorController.getPenStyle();
      penStyle = PenStyle.parse(value);
      setState(() => penColor = penStyle.color);
    }
  }

  closeEditorController() async {
    if (widget.filePath != sRealtimeManager.fileStruct.filePath) {
      await _editorController.close();
    }
  }

  _onNotepadStateEvent(NotepadStateEvent event) async {
    if (mounted) setState(() => notepadState = event.state);
  }

  /*-----------------------------------------------------------------------
  *
  * Widgets
  *
  * -----------------------------------------------------------------------*/
  @override
  Widget build(BuildContext context) {
    return buildScaffold(
      context,
      appBar: AppBar(
        actions: <Widget>[
          FlatButton(
            child: Text('Myscript'),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => FunctionListWidget(
                  items: myscriptList,
                ),
              );
            },
          ),
          FlatButton(
            child: Text(
              notepadState == NotepadState.Connected ? '已连接' : '未连接',
              style: TextStyle(
                color: Colors.white,
              ),
            ),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => notepadState == NotepadState.Connected
                      ? NotepadDetailPage(sNotepadManager.connectedDevice)
                      : DeviceList(),
                ),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: <Widget>[
          buildContent(),
          Align(
            alignment: Alignment.topCenter,
            child: Container(
              height: 60,
              color: Colors.white,
              child: buildTopMenus(),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: 60,
              color: Colors.white,
              child: buildBottomMenus(),
            ),
          ),
        ],
      ),
    );
  }

  buildContent() {
    return Center(
      child: AspectRatio(
        aspectRatio: 157.5 / 210.0,
        child: Stack(
          children: <Widget>[
            Align(
              alignment: Alignment.center,
              child: Image.asset('images/noteskin.png'),
            ),
            Align(
              alignment: Alignment.center,
              child: EditorView(
                onCreated: (id) async {
                  Toast.toast(
                    context,
                    msg: '加载中（需要延迟一会再去绑定view，否则可能加载UI失败）',
                  );
                  await Future.delayed(Duration(milliseconds: 1000), () {});
                  await initEditorController();
                  await _editorController.bindPlatformView(id);
                },
                onDisposed: (id) async {
                  await _editorController?.unbindPlatformView(id);
                  await closeEditorController();
                },
              ),
            ),
            if (penColor != null)
              Align(
                alignment: Alignment.topCenter,
                child: Container(
                  width: 20,
                  height: 20,
                  color: Color(getColorFromHex(penColor)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  buildTopMenus() {
    return menus(
      titles: [
        'IntoRealtime',
        'SyncMemo',
      ],
      functions: [
        () async {
          if (sNotepadManager.notepadState != NotepadState.Connected) {
            Toast.toast(context, msg: 'Please connect device');
            return;
          }
          if (sNotepadManager.deviceMode != NotepadMode.Sync) {
            Toast.toast(context, msg: 'Please setMode:SYNC in Notepad');
            return;
          }
          if (sRealtimeManager.fileStruct.filePath == widget.filePath) {
            Toast.toast(context, msg: '已经是实时笔记了，不需要再次设置');
            return;
          }

          try {
            await sRealtimeManager.intoRealtime(FileStruct(
              widget.filePath,
              _editorController,
            ));
            Toast.toast(context, msg: 'IntoRealtime success');
          } catch (e) {
            Toast.toast(context, msg: 'IntoRealtime erro = ${e.toString()}');
          }
        },
        () async {
          print('橡皮擦');
          //  连接设备
          if (sNotepadManager.notepadState != NotepadState.Connected) {
            Toast.toast(context, msg: '请先连接设备');
            return;
          }

          //  检测离线笔记的数量
          var m = await sNotepadManager.getMemoSummary();
          if (m.memoCount == 0) {
            Toast.toast(context, msg: '请在COMMON模式下书写离线笔记');
            return;
          }

          //  先清空当前的笔记
          await _editorController.clear();

          //  开始导入离线笔记(只导入栈顶的那个笔记)
          var memoData = await sNotepadManager.importStackTopMemo();

          //  格式化点位信息
          var pointerEvents = formatPointerEvents(memoData.pointers);

          //  交给myscript
          await _editorController.syncPointerEvents(pointerEvents);

          //  删除设备中栈顶的笔记
          await sNotepadManager.deleteMemo();

          //  立即进行识别
          await exportText();
        },
      ],
    );
  }

  buildBottomMenus() {
    return menus(
      titles: [
        '回放',
        '橡皮擦',
        '后退',
        '前进',
      ],
      opacitys: [
        1.0,
        _pointerType == IINKPointerTypeFlutter.eraser ? 1 : 0.5,
        canUndo ? 1 : 0.5,
        canRedo ? 1 : 0.5,
      ],
      functions: [
        () async {
          print('回放');
          pushReplay(_editorController, penStyle, context);
        },
        () async {
          print('橡皮擦');
          if (sRealtimeManager.fileStruct.filePath != widget.filePath) {
            Toast.toast(context, msg: '请将当前笔记设置为实时笔记，点击IntoRealtime');
            return;
          }
          var isE = _pointerType == IINKPointerTypeFlutter.eraser;
          print('isE = $isE');
          await setIsEraser(!isE);
        },
        () async {
          print('撤销');
          if (!canUndo) {
            Toast.toast(
              context,
              msg: 'canRedo = ${canUndo}',
            );
            await resetUndoAndRedo();
            return;
          }
          await _editorController.undo();
          await resetUndoAndRedo();
        },
        () async {
          print('前进');
          if (!canRedo) {
            Toast.toast(
              context,
              msg: 'canRedo = ${canRedo}',
            );
            await resetUndoAndRedo();
            return;
          }
          await _editorController.redo();
          await resetUndoAndRedo();
        },
      ],
    );
  }

  /*-----------------------------------------------------------------------
  *
  * Myscript Methods
  *
  * -----------------------------------------------------------------------*/
  initFunctionList() {
    myscriptList = [
      FunctionItem('setPenStyle', callBack: setPenStyle),
      FunctionItem('getPenStyle', callBack: getPenStyle),
      FunctionItem('exportText', callBack: exportText),
      FunctionItem('exportPNG', callBack: exportPNG),
      FunctionItem('exportJPG', callBack: exportJPG),
      FunctionItem('exportJIIX', callBack: exportJIIX),
      FunctionItem('exportJIIXAndParse', callBack: exportJIIXAndParse),
      FunctionItem('exportGIF', callBack: exportGIF),
      FunctionItem(
        'syncPointerEvent',
        content: 'Use mock-data',
        callBack: handleSyncPointerEvent,
      ),
      FunctionItem(
        'syncPointerEvents',
        content: 'Use mock-data',
        callBack: handleSyncPointerEvents,
      ),
      FunctionItem('"王"字，可尝试重复n次，分别进行识别', callBack: mockdata),
      FunctionItem('clear', callBack: clear),
    ];
  }

  setPenStyle() async {
    var colorStr = '0123456789abcdef';
    var color = '#';
    for (int i = 0; i < 6; i++) {
      var index = Random().nextInt(colorStr.length).toInt();
      color += colorStr.substring(index, index + 1);
    }

    var newPenStyle = penStyle.clone(
      color: color, //  '#00ff38'
      myscriptPenWidth: 2.5,
      myscriptPenBrush: MyscriptPenBrush(MyscriptPenBrushType.FountainPen),
    );
    await _editorController.setPenStyle(newPenStyle.fromat());
    var value = await _editorController.getPenStyle();
    penStyle = PenStyle.parse(value);
    setState(() => penColor = penStyle.color);
    Toast.toast(
      context,
      msg: 'setPenStyle:\n ${penStyle.fromat()}',
    );
  }

  getPenStyle() async {
    var value = await _editorController.getPenStyle();
    Toast.toast(
      context,
      msg: 'getPenStyle:\n ${value}',
    );
  }

  exportText() async {
    var covert = await _editorController.exportText();
    Toast.toast(context, msg: 'exportText = $covert');
  }

  clear() async {
    await _editorController.clear();
    Toast.toast(context, msg: "clear");
  }

  exportGIF() async {
    var jiix = await _editorController.exportJIIX();
    var pointerEvents = await _editorController.parseJIIX(jiix);
    final skinByteData = await rootBundle.load('images/noteskin.png');
    final skinBytes = skinByteData.buffer.asUint8List();

    var documentsDir = await getApplicationDocumentsDirectory();
    var ptsFile = File("${documentsDir.path}/share_gif.pts");
    var gifEditorController = await EditorController.create(ptsFile.path);
    (await ptsFile.exists())
        ? await gifEditorController.openPackage(ptsFile.path)
        : await gifEditorController.createPackage(ptsFile.path);
    await gifEditorController.clear();
    var gifFilePath = await gifEditorController.exportGIF(
      skinBytes,
      pointerEvents,
      File("${documentsDir.path}/share_gif.gif").path,
    );
    Toast.toast(
      context,
      img: Image.file(File(gifFilePath)),
      msg: 'exportGIF',
    );
  }

  exportJIIXAndParse() async {
    var jiix = await _editorController.exportJIIX();
    var list = await _editorController.parseJIIX(jiix);
    Toast.toast(context, msg: "exportJIIX list.length = ${list.length}");
  }

  exportJIIX() async {
    var jiix = await _editorController.exportJIIX();
    Toast.toast(context, msg: "exportJIIX list.length = ${jiix}");
  }

  exportJPG() async {
    final skinByteData = await rootBundle.load('images/noteskin.png');
    final skinBytes = skinByteData.buffer.asUint8List();
    var jpgBytes = await _editorController.exportJPG(skinBytes);

    Toast.toast(
      context,
      bgColor: Colors.red,
      img: Image.memory(jpgBytes),
      msg: '红色为屏幕背景色\nexportJPG jpg.length = ${jpgBytes.length}',
    );
  }

  exportPNG() async {
    final skinByteData = await rootBundle.load('images/noteskin.png');
    final skinBytes = skinByteData.buffer.asUint8List();
    var pngBytes = await _editorController.exportPNG(null);
    Toast.toast(
      context,
      bgColor: Colors.red,
      img: Image.memory(pngBytes),
      msg: '红色为屏幕背景色\nexportPNG png.length = ${pngBytes.length}',
    );
  }

  handleSyncPointerEvent() async {
    print('===================================handleSyncPointerEvent');
    if (_editorController == null) return;
    final pointers = 200; //  测试数量大于5000时，会不会切割
    var startTime = DateTime.now().millisecondsSinceEpoch;
    for (var i = 0; i < pointers; i++) {
      var eventType = IINKPointerEventTypeFlutter.move;
      if (i == 0) eventType = IINKPointerEventTypeFlutter.down;
      if (i == pointers - 1) eventType = IINKPointerEventTypeFlutter.up;

      var x = Random().nextInt(14800).toDouble();
      var y = Random().nextInt(21000).toDouble();
      var pe = IINKPointerEventFlutter.shared.clone(
        x: x * viewScale,
        y: y * viewScale,
        t: startTime + 5 * i,
        eventType: eventType,
      );
      print(
          '************ _handleSyncPointerEvent type = ${IINKPointerEventTypeFlutterDescription(eventType)} i = ${i}');
      await _editorController.syncPointerEvent(pe);
      if (eventType == IINKPointerEventTypeFlutter.up) await firstStroke(true);
    }
  }

  handleSyncPointerEvents() async {
    if (_editorController == null) return;
    final pointers = 200; //  测试数量大于5000时，会不会切割
    var list = List<IINKPointerEventFlutter>();
    var startTime = DateTime.now().millisecondsSinceEpoch;
    for (var i = 0; i < pointers; i++) {
      var eventType = IINKPointerEventTypeFlutter.move;
      if (i == 0) eventType = IINKPointerEventTypeFlutter.down;
      if (i == pointers - 1) eventType = IINKPointerEventTypeFlutter.up;

      var x = Random().nextInt(14800).toDouble();
      var y = Random().nextInt(21000).toDouble();
      var pe = IINKPointerEventFlutter.shared.clone(
        x: x * viewScale,
        y: y * viewScale,
        t: startTime + 5 * i,
        eventType: eventType,
      );
      list.add(pe);
    }
    await _editorController.syncPointerEvents(list);
    await firstStroke(true);
  }

  mockdata() async {
    print('===================================mockdata');
    if (_editorController == null) return;

    //  init
    var _prePointer = IINKPointerEventFlutter.shared;
    var x = 3000.toInt();
    var y = 3000.toInt();
    var offset = 100.toInt();

    //  第一笔：横（50个点）
    print('第一笔：横（50个点）');
    for (var i = 0; i < 50; i++) {
      var p = i == 49 ? 0 : (Random().nextInt(400) + 10);
      var pointer = NotePenPointer(x + offset * i, y, -1, p);
      print(pointer.toMap());
      var pe = handlePointerEvent(_prePointer, pointer);
      if (pe == null) continue;
      _prePointer = pe;
      await _editorController.syncPointerEvent(_prePointer);
      if (_prePointer.eventType == IINKPointerEventTypeFlutter.up) {
        await _editorController.save();
        await firstStroke(true);
      }
    }

    //  第二笔：横（50个点）
    print('第二笔：横（50个点）');
    for (var i = 0; i < 50; i++) {
      var p = i == 49 ? 0 : (Random().nextInt(400) + 10);
      var pointer = NotePenPointer(x + offset * i, y + 25 * offset, -1, p);
      var pe = handlePointerEvent(_prePointer, pointer);
      if (pe == null) continue;
      _prePointer = pe;
      await _editorController.syncPointerEvent(_prePointer);
      if (_prePointer.eventType == IINKPointerEventTypeFlutter.up) {
        await _editorController.save();
        await firstStroke(true);
      }
    }

    //  第三笔：竖（50个点）
    print('第三笔：竖（50个点）');
    for (var i = 0; i < 50; i++) {
      var p = i == 49 ? 0 : (Random().nextInt(400) + 10);
      var pointer = NotePenPointer(x + 25 * offset, y + offset * i, -1, p);
      var pe = handlePointerEvent(_prePointer, pointer);
      if (pe == null) continue;
      _prePointer = pe;
      await _editorController.syncPointerEvent(_prePointer);
      if (_prePointer.eventType == IINKPointerEventTypeFlutter.up) {
        await _editorController.save();
        await firstStroke(true);
      }
    }

    //  第四笔：横（50个点）
    print('第四笔：横（50个点）');
    for (var i = 0; i < 50; i++) {
      var p = i == 49 ? 0 : (Random().nextInt(400) + 10);
      var pointer = NotePenPointer(x + offset * i, y + 49 * offset, -1, p);
      var pe = handlePointerEvent(_prePointer, pointer);
      if (pe == null) continue;
      _prePointer = pe;
      await _editorController.syncPointerEvent(_prePointer);
      if (_prePointer.eventType == IINKPointerEventTypeFlutter.up) {
        await _editorController.save();
        await firstStroke(true);
      }
    }
  }
}
