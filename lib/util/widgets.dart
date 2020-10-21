import 'package:flutter/material.dart';
import 'package:notepad_myscript_demo/ConnectDevice/DeviceList.dart';
import 'package:notepad_myscript_demo/ConnectDevice/NotepadDetailPage.dart';
import 'package:notepad_myscript_demo/manager/NotepadManager.dart';
import 'package:notepad_myscript_demo/manager/NotepadUtil.dart';
import 'package:notepad_myscript_demo/util/sizes.dart';

Scaffold buildScaffold(
  BuildContext context, {
  AppBar appBar,
  Widget body,
  NotepadState notepadState,
}) {
  return Scaffold(
    appBar: appBar,
    body: body,
    floatingActionButton: notepadState != null
        ? FloatingActionButton(
            child: Text(
              notepadState == NotepadState.Connected ? '已连接' : '未连接',
              style: TextStyle(
                color: Colors.white,
              ),
            ),
            backgroundColor: notepadState == NotepadState.Connected
                ? Colors.blue
                : Colors.grey,
            highlightElevation: 6,
            elevation: 0,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => notepadState == NotepadState.Connected
                      ? NotepadDetailPage(sNotepadManager.connectedDevice)
                      : DeviceList(),
                ),
              );
            },
          )
        : null,
  );
}

menus<T>({
  @required List<String> titles,
  @required List<Function> functions,
  Color bgColor = Colors.white,
  Color color = Colors.black87,
  double fontSize = 13,
  double imageSize = 20,
  double height = 60,
  List<double> opacitys,
}) {
  List<Widget> _renderWidgets() {
    List<Widget> widgets = [];
    column(int index) => Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (titles != null)
              Text(
                titles[index],
                style: TextStyle(
                  fontSize: fontSize,
                  color: color,
                ),
              ),
          ],
        );

    for (int i = 0; i < titles.length; i++) {
      final widget = Opacity(
        opacity: opacitys == null ? 1 : opacitys[i],
        child: GestureDetector(
          onTap: functions[i],
          child: Container(
            height: height,
            color: bgColor,
            width: ScreenWidth / titles.length,
            child: column(i),
          ),
        ),
      );
      widgets.add(widget);
    }
    return widgets;
  }

  return Row(
    children: _renderWidgets(),
    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
  );
}
