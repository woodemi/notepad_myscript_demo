import 'package:flutter/material.dart';
import 'package:notepad_myscript_demo/ConnectDevice/DeviceList.dart';
import 'package:notepad_myscript_demo/ConnectDevice/NotepadDetailPage.dart';
import 'package:notepad_myscript_demo/manager/NotepadManager.dart';
import 'package:notepad_myscript_demo/manager/NotepadUtil.dart';

Scaffold buildScaffold(
  BuildContext context, {
  AppBar appBar,
  Widget body,
  NotepadState notepadState,
}) {
  return Scaffold(
    appBar: appBar,
    body: body,
    floatingActionButton: FloatingActionButton(
      child: Text(
        notepadState == NotepadState.Connected ? '已连接' : '未连接',
        style: TextStyle(
          color: Colors.white,
        ),
      ),
      backgroundColor:
          notepadState == NotepadState.Connected ? Colors.blue : Colors.grey,
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
    ),
  );
}
