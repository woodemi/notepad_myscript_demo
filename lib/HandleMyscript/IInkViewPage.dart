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
import 'package:notepad_myscript_demo/util/NormalScaffold.dart';
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

  EditorController editorController;

  String penColor;

  var notepadState = sNotepadManager.notepadState;

  StreamSubscription<NotepadStateEvent> _notepadStateSubscription;

  @override
  void initState() {
    super.initState();
    initFunctionList();

    _notepadStateSubscription =
        sNotepadManager.notepadStateStream.listen(_onNotepadStateEvent);
  }

  @override
  void dispose() {
    super.dispose();
    _notepadStateSubscription.cancel();
    _notepadStateSubscription = null;
  }

  @override
  Widget build(BuildContext context) {
    return buildScaffold(
      context,
      appBar: AppBar(
        title: Text('IInkView'),
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
        ],
      ),
      body: Stack(
        children: <Widget>[
          buildContent(),
          buildMenu(),
        ],
      ),
      notepadState: notepadState,
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
                  await initEditorController();
                  await editorController.bindPlatformView(id);
                },
                onDisposed: (id) async {
                  await editorController?.unbindPlatformView(id);
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

  buildMenu() {
    return Container(
      height: 60,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          RaisedButton(
            child: Text('IntoRealtime'),
            onPressed: () async {
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
                  editorController,
                ));
                Toast.toast(context, msg: 'IntoRealtime success');
              } catch (e) {
                Toast.toast(context,
                    msg: 'IntoRealtime erro = ${e.toString()}');
              }
            },
          ),
          RaisedButton(
            child: Text('SyncMemo'),
            onPressed: () async {
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
              await editorController.clear();

              //  开始导入离线笔记(只导入栈顶的那个笔记)
              var memoData = await sNotepadManager.importStackTopMemo();

              //  格式化点位信息
              var pointerEvents = formatPointerEvents(memoData.pointers);

              //  交给myscript
              await editorController.syncPointerEvents(pointerEvents);

              //  删除设备中栈顶的笔记
              await sNotepadManager.deleteMemo();

              //  立即进行识别
              await exportText();
            },
          ),
        ],
      ),
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
    var s = await editorController.getPenStyle();
    var currentPenStyle = PenStyle.parse(s);
    var colorStr = '0123456789abcdef';
    var color = '#';

    for (int i = 0; i < 6; i++) {
      var index = Random().nextInt(colorStr.length).toInt();
      color += colorStr.substring(index,index+1);
    }

    var penStyle = currentPenStyle.clone(
      color: color, //  '#00ff38'
      myscriptPenWidth: 2.5,
      myscriptPenBrush: MyscriptPenBrush(MyscriptPenBrushType.FountainPen),
    );
    await editorController.setPenStyle(penStyle.fromat());
    var value = await editorController.getPenStyle();
    currentPenStyle = PenStyle.parse(value);
    setState(() => penColor = currentPenStyle.color);
    Toast.toast(
      context,
      msg: 'setPenStyle:\n ${currentPenStyle.fromat()}',
    );
  }

  getPenStyle() async {
    var value = await editorController.getPenStyle();
    Toast.toast(
      context,
      msg: 'getPenStyle:\n ${value}',
    );
  }

  Future exportText() async {
    var covert = await editorController.exportText();
    Toast.toast(context, msg: 'exportText = $covert');
  }

  Future clear() async {
    await editorController.clear();
    Toast.toast(context, msg: "clear");
  }

  Future exportGIF() async {
    var jiix = await editorController.exportJIIX();
    var pointerEvents = await editorController.parseJIIX(jiix);
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

  Future exportJIIXAndParse() async {
    var jiix = await editorController.exportJIIX();
    var list = await editorController.parseJIIX(jiix);
    Toast.toast(context, msg: "exportJIIX list.length = ${list.length}");
  }

  Future exportJIIX() async {
    var jiix = await editorController.exportJIIX();
    Toast.toast(context, msg: "exportJIIX list.length = ${jiix}");
  }

  Future exportJPG() async {
    final skinByteData = await rootBundle.load('images/noteskin.png');
    final skinBytes = skinByteData.buffer.asUint8List();
    var jpgBytes = await editorController.exportJPG(skinBytes);

    Toast.toast(
      context,
      bgColor: Colors.red,
      img: Image.memory(jpgBytes),
      msg: '红色为屏幕背景色\nexportJPG jpg.length = ${jpgBytes.length}',
    );
  }

  Future exportPNG() async {
    final skinByteData = await rootBundle.load('images/noteskin.png');
    final skinBytes = skinByteData.buffer.asUint8List();
    var pngBytes = await editorController.exportPNG(null);
    Toast.toast(
      context,
      bgColor: Colors.red,
      img: Image.memory(pngBytes),
      msg: '红色为屏幕背景色\nexportPNG png.length = ${pngBytes.length}',
    );
  }

  handleSyncPointerEvent() async {
    print('===================================');
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
      await editorController.syncPointerEvent(pe);
    }
  }

  handleSyncPointerEvents() async {
    if (editorController == null) return;
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
    await editorController.syncPointerEvents(list);
  }

  mockdata() async {
    //  init
    var _preEventType = IINKPointerEventTypeFlutter.up;
    var x = 3000.toInt();
    var y = 3000.toInt();
    var offset = 100.toInt();

    //  第一笔：横（50个点）
    for (var i = 0; i < 50; i++) {
      var p = i == 49 ? 0 : (Random().nextInt(400) + 10);
      var pointer = NotePenPointer(x + offset * i, y, -1, p);
      print(pointer.toMap());
      var pe = handlePointerEvent(_preEventType, pointer);
      await editorController.syncPointerEvent(pe);

      _preEventType = pe.eventType;
    }

    //  第二笔：横（50个点）
    for (var i = 0; i < 50; i++) {
      var p = i == 49 ? 0 : (Random().nextInt(400) + 10);
      var pointer = NotePenPointer(x + offset * i, y + 25 * offset, -1, p);
      var pe = handlePointerEvent(_preEventType, pointer);
      await editorController.syncPointerEvent(pe);

      _preEventType = pe.eventType;
    }

    //  第三笔：竖（50个点）
    for (var i = 0; i < 50; i++) {
      var p = i == 49 ? 0 : (Random().nextInt(400) + 10);
      var pointer = NotePenPointer(x + 25 * offset, y + offset * i, -1, p);
      var pe = handlePointerEvent(_preEventType, pointer);
      await editorController.syncPointerEvent(pe);

      _preEventType = pe.eventType;
    }

    //  第四笔：横（50个点）
    for (var i = 0; i < 50; i++) {
      var p = i == 49 ? 0 : (Random().nextInt(400) + 10);
      var pointer = NotePenPointer(x + offset * i, y + 49 * offset, -1, p);
      var pe = handlePointerEvent(_preEventType, pointer);
      await editorController.syncPointerEvent(pe);

      _preEventType = pe.eventType;
    }
  }

  //  '#FFE82A'   ->   0xFFFFE82A
  int getColorFromHex(String hexColor) {
    hexColor = hexColor.toUpperCase().replaceAll("#", "");
    if (hexColor.length == 6) hexColor = "FF" + hexColor;
    return int.parse(hexColor, radix: 16);
  }

  initEditorController() async {
    if (sRealtimeManager.fileStruct.filePath == widget.filePath) {
      setState(() => editorController = sRealtimeManager.fileStruct.editorController);
      return;
    }

    var newController = await EditorController.create(widget.filePath);
    setState(() => editorController = newController);

    (await File(widget.filePath).exists())
        ? await editorController.openPackage(widget.filePath)
        : await editorController.createPackage(widget.filePath);
  }

  closeEditorController() async {
    if (sRealtimeManager.fileStruct.filePath != widget.filePath) {
      await editorController.close();
    }
  }

  _onNotepadStateEvent(NotepadStateEvent event) async {
    if (mounted) setState(() => notepadState = event.state);
  }
}
