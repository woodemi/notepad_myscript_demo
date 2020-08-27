import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:myscript_iink/EditorController.dart';
import 'package:myscript_iink/EditorView.dart';
import 'package:myscript_iink/DeviceSize.dart';
import 'package:myscript_iink/common.dart';
import 'package:myscript_iink_example/FunctionListPage.dart';
import 'package:path_provider/path_provider.dart';

import 'Toast.dart';

class IInkViewPage extends StatefulWidget {
  final String filePath;

  IInkViewPage(this.filePath);

  @override
  State<StatefulWidget> createState() => _IInkViewPageState();
}

class _IInkViewPageState extends State<IInkViewPage> {
  var functionList = [
    FunctionItem('setPenStyle'),
    FunctionItem('getPenStyle'),
    FunctionItem('syncPointerEvent', subTitle: 'Use mock-data'),
    FunctionItem('syncPointerEvents', subTitle: 'Use mock-data'),
    FunctionItem('exportText'),
    FunctionItem('exportPNG'),
    FunctionItem('exportJPG'),
    FunctionItem('exportJIIX'),
    FunctionItem('exportJIIXAndParse'),
    FunctionItem('exportGIF'),
  ];

  EditorController editorController;
  String penColor;

  initEditorController() async {
    var newController = await EditorController.create(widget.filePath);
    setState(() => editorController = newController);

    (await File(widget.filePath).exists())
        ? await editorController.openPackage(widget.filePath)
        : await editorController.createPackage(widget.filePath);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('IInkView'),
        actions: <Widget>[
          FlatButton(
            child: Text('FunctionList'),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => FunctionListWidget(
                  items: functionList,
                  call: _functionCall,
                ),
              );
            },
          )
        ],
      ),
      body: Center(
        child: AspectRatio(
          aspectRatio: 157.5 / 210.0,
          child: Stack(
            children: <Widget>[
              Align(
                alignment: Alignment.center,
                child: Image.asset('images/noteskin1.png'),
              ),
              Align(
                alignment: Alignment.center,
                child: EditorView(
                  onCreated: (id) async {
                    if (editorController == null) await initEditorController();
                    await editorController.bindPlatformView(id);
                  },
                  onDisposed: (id) async {
                    if (editorController != null) {
                      await editorController.unbindPlatformView(id);
                      await editorController.close();
                    }
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
      ),
    );
  }

  _functionCall(String title) async {
    if (editorController == null) return;
    switch (title) {
      case 'setPenStyle':
        var s = await editorController.getPenStyle();
        var currentPenStyle = PenStyle.parse(s);
        var list = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '10', 'a', 'b', 'c', 'd', 'e', 'f'];
        var color = '#';

        for (int i = 0; i < 6; i++)
          color += list[Random().nextInt(list.length).toInt()];

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
        break;
      case 'getPenStyle':
        var value = await editorController.getPenStyle();
        Toast.toast(
          context,
          msg: 'getPenStyle:\n ${value}',
        );
        break;
      case 'syncPointerEvent':
        _handleSyncPointerEvent();
        break;
      case 'syncPointerEvents':
        _handleSyncPointerEvents();
        break;
      case 'exportText':
        var covert = await editorController.exportText();
        Toast.toast(context, msg: 'exportText = $covert');
        break;
      case 'exportPNG':
        final skinByteData = await rootBundle.load('images/noteskin1.png');
        final skinBytes = skinByteData.buffer.asUint8List();
        var pngBytes = await editorController.exportPNG(skinBytes);
        Toast.toast(context,
            img: Image.memory(pngBytes),
            msg: 'exportPNG png.length = ${pngBytes.length}');
        break;
      case 'exportJPG':
        final skinByteData = await rootBundle.load('images/noteskin1.png');
        final skinBytes = skinByteData.buffer.asUint8List();
        var pngBytes = await editorController.exportJPG(skinBytes);

        Toast.toast(context,
            img: Image.memory(pngBytes),
            msg: 'exportJPG jpg.length = ${pngBytes.length}');
        break;
      case 'exportJIIX':
        var jiix = await editorController.exportJIIX();
        Toast.toast(context, msg: "exportJIIX list.length = ${jiix}");
        break;
      case 'exportJIIXAndParse':
        var jiix = await editorController.exportJIIX();
        var list = await editorController.parseJIIX(jiix);
        Toast.toast(context, msg: "exportJIIX list.length = ${list.length}");
        break;
      case 'exportGIF':
        var jiix = await editorController.exportJIIX();
        var pointerEvents = await editorController.parseJIIX(jiix);
        final skinByteData = await rootBundle.load('images/noteskin1.png');
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
        break;
      case 'clear':
        await editorController.clear();
        Toast.toast(context, msg: "clear");
        break;
      default:
        break;
    }
  }

  _handleSyncPointerEvent() async {
    final pointers = 10000; //  测试数量大于5000时，会不会切割
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
      print('************ _handleSyncPointerEvent type = ${IINKPointerEventTypeFlutterDescription(eventType)} i = ${i}');
      await editorController.syncPointerEvent(pe);
    }
  }

  _handleSyncPointerEvents() async {
    if (editorController == null) return;
    final pointers = 10000; //  测试数量大于5000时，会不会切割
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

  //  '#FFE82A'   ->   0xFFFFE82A
  int getColorFromHex(String hexColor) {
    hexColor = hexColor.toUpperCase().replaceAll("#", "");
    if (hexColor.length == 6) hexColor = "FF" + hexColor;
    return int.parse(hexColor, radix: 16);
  }
}
