import 'dart:async';
import 'dart:core';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:myscript_iink/EditorController.dart';
import 'package:myscript_iink/EditorView.dart';
import 'package:myscript_iink/common.dart';
import 'package:notepad_myscript_demo/util/widgets.dart';

import '../manager/NotepadUtil.dart';

pushReplay(
  EditorController controller,
  PenStyle penStyle,
  BuildContext context,
) async {
  var jiix = await controller.exportJIIX();
  var pointEvents = await controller.parseJIIX(jiix);
  if (pointEvents.length == 0) {
    pointEvents = await controller.parseJIIX(jiix);
  }
  print('pointEvents = ${pointEvents.length}');
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => NoteReplayPage(pointEvents, penStyle),
    ),
  );
}

class NoteReplayPage extends StatefulWidget {
  NoteReplayPage(this.pointEvents, this.penStyle);

  List<IINKPointerEventFlutter> pointEvents;
  PenStyle penStyle;

  @override
  _NoteReplayPageState createState() => _NoteReplayPageState();
}

class _NoteReplayPageState extends State<NoteReplayPage> {
  EditorController editorController;
  String filePath;

  final _allSpeeds = [0.5, 1.0, 2.0, 4.0, 8.0, 16.0];
  int currentSpeedIndex = 1;

  setCurrentSpeedIndex(int value) {
    setState(() {
      if (value < 0)
        currentSpeedIndex = 0;
      else if (value > _allSpeeds.length)
        currentSpeedIndex = _allSpeeds.length - 1;
      else
        currentSpeedIndex = value;
    });
  }

  Timer _countdownTimer;
  bool _isPause = false;
  int currentIndex = 0;

  setCurrentIndex(int value) {
    setState(() {
      if (value < 0)
        currentIndex = 0;
      else if (value > widget.pointEvents.length)
        currentIndex = widget.pointEvents.length - 1;
      else
        currentIndex = value;
    });
  }

  int get _currentSpeed {
    if (currentSpeedIndex < 0)
      currentSpeedIndex = 0;
    else if (currentSpeedIndex > _allSpeeds.length)
      currentSpeedIndex = _allSpeeds.length - 1;
    return (_allSpeeds[currentSpeedIndex >= _allSpeeds.length
                ? _allSpeeds.length - 1
                : currentSpeedIndex] *
            200)
        .toInt();
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    _isPause = true;
    _countdownTimer?.cancel();
    _countdownTimer = null;
    close();
  }

  close() async {
    await editorController?.close();
  }

  _closeEditorController() async {
    await editorController.close();
  }

  _initEditorViewController() async {
    if (editorController == null) {
      filePath = await NewFilePath();
      editorController = await EditorController.create(filePath);
      (await File(filePath).exists())
          ? await editorController.openPackage(filePath)
          : await editorController.createPackage(filePath);
      await editorController.setPenStyle(widget.penStyle.fromat());
    }
    await editorController.clear();
  }

  startPlay() async {
    print('filePath = $filePath');
    final pointers = widget.pointEvents.length; //  测试数量大于5000时，会不会切割
    for (var i = 0; i < pointers; i++) {
      await editorController.syncPointerEvent(widget.pointEvents[i]);
    }
    return;
    if (_countdownTimer != null) return;
    _countdownTimer = Timer.periodic(Duration(milliseconds: 500), (timer) {
      if (currentIndex < widget.pointEvents.length - 1) {
        if (!_isPause) {
          var list = List<IINKPointerEventFlutter>();
          var currentDate = widget.pointEvents[currentIndex].t;
          var targetDate = currentDate + _currentSpeed;
          int maxNum = (_currentSpeed * 0.2).toInt();
          for (var index = currentIndex;
              index < widget.pointEvents.length;
              index++) {
            setCurrentIndex(index);
            if (widget.pointEvents[currentIndex].t > targetDate) break;
            list.add(widget.pointEvents[currentIndex]);
            if (list.length >= maxNum) break; //  按照时间回放，每秒最多200点
          }
          if (list.length == 0) {
            setState(() => _isPause = true);
            return;
          }

          if (list.first.eventType != IINKPointerEventTypeFlutter.down)
            list.insert(0,
                list.first.clone(eventType: IINKPointerEventTypeFlutter.down));
          if (list.last.eventType != IINKPointerEventTypeFlutter.up)
            list.add(
                list.last.clone(eventType: IINKPointerEventTypeFlutter.up));
          editorController.syncPointerEvents(list);
        }
      } else {
        if (_isPause == false) {
          setState(() => _isPause = true);
          Navigator.pop(context);
        }
        print('播放结束');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return buildScaffold(
      context,
      appBar: AppBar(
        title: Text('Replay Note'),
      ),
      body: Stack(
        children: <Widget>[
          buildContent(),
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
                  await _initEditorViewController();
                  await editorController.bindPlatformView(id);
                  startPlay();
                },
                onDisposed: (id) async {
                  await editorController?.unbindPlatformView(id);
                  await _closeEditorController();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
