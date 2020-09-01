import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:myscript_iink/EditorController.dart';
import 'package:path_provider/path_provider.dart';
import 'package:notepad_myscript_demo/ConnectDevice/DeviceList.dart';
import 'package:notepad_myscript_demo/ConnectDevice/NotepadDetailPage.dart';
import 'package:notepad_myscript_demo/HandleMyscript/ConfigMyscriptEngine.dart';
import 'package:notepad_myscript_demo/HandleMyscript/IInkViewPage.dart';
import 'package:notepad_myscript_demo/manager/NotepadManager.dart';
import 'package:notepad_myscript_demo/manager/NotepadRealtime.dart';
import 'package:notepad_myscript_demo/manager/NotepadUtil.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: HomePage());
  }
}

class HomePage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  var list = List<FileSystemEntity>();

  StreamSubscription<NotepadStateEvent> _notepadStateSubscription;

  var realtimeFilePath = '';

  var deleteFileSwich = false;

  @override
  void initState() {
    super.initState();
    _requestListDocumentsDirectory();
    _notepadStateSubscription =
        sNotepadManager.notepadStateStream.listen(_onNotepadStateEvent);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('FileList'),
        actions: <Widget>[
          FlatButton(
            child: Text('RefreshList'),
            onPressed: () async {
              await _requestListDocumentsDirectory();
            },
          ),
          FlatButton(
            child: Text('Notepad'),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) =>
                      sNotepadManager.notepadState == NotepadState.Connected
                          ? NotepadDetailPage(sNotepadManager.connectedDevice)
                          : DeviceList(),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          buildMenu(),
          Container(
            width: double.maxFinite,
            height: 1,
            color: Colors.red,
          ),
          Expanded(
            child: buildListView(),
          ),
        ],
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
            child: Text('my-Settings'),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => ConfigMyscriptEngine(),
                ),
              );
            },
          ),
          RaisedButton(
            child: Text('CreateFile'),
            onPressed: () async {
              var filePath = await NewFilePath();
              var newController = await EditorController.create(filePath);
              (await File(filePath).exists())
                  ? await newController.openPackage(filePath)
                  : await newController.createPackage(filePath);
              await newController.clear();
              await _requestListDocumentsDirectory();
            },
          ),
          RaisedButton(
            child: Text(
              'deleteFile',
              style: TextStyle(
                color: deleteFileSwich ? Colors.red : Colors.black,
              ),
            ),
            onPressed: () {
              setState(() => deleteFileSwich = !deleteFileSwich);
            },
          ),
        ],
      ),
    );
  }

  ListView buildListView() {
    return ListView.separated(
      itemBuilder: (context, index) => ListTile(
        title: Text(
          list[index].path +
              (list[index].path == realtimeFilePath ? '  【正在实时的笔记】' : ''),
          style: TextStyle(
            color: list[index].path == realtimeFilePath
                ? Colors.red
                : Colors.black,
          ),
        ),
        trailing: deleteFileSwich ? Icon(Icons.delete_forever) : null,
        onTap: () async {
          if (deleteFileSwich) {
            File file = await File(list[index].path);
            await file.deleteSync(recursive: true);
            await _requestListDocumentsDirectory();
          } else {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => IInkViewPage(list[index].path),
              ),
            );
          }
        },
      ),
      separatorBuilder: (context, index) => Divider(),
      itemCount: list.length,
    );
  }

  _requestListDocumentsDirectory() async {
    var directory = await getApplicationDocumentsDirectory();
    setState(() => list
      ..clear()
      ..addAll(directory.listSync()));
    print('list.length = ${list.length}');
    for (var file in list) print('list.path = ${file.path}');
    print(
        'sRealtimeManager.realtimeFilePath = ${sRealtimeManager.fileStruct.filePath}');
    setState(() {
      realtimeFilePath = sRealtimeManager.fileStruct.filePath;
    });
  }

  _onNotepadStateEvent(NotepadStateEvent event) async {
    await _requestListDocumentsDirectory();
  }
}
