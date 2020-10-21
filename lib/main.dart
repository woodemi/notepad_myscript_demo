import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:myscript_iink/EditorController.dart';
import 'package:notepad_myscript_demo/util/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:notepad_myscript_demo/HandleMyscript/ConfigMyscriptEngine.dart';
import 'package:notepad_myscript_demo/HandleMyscript/IInkViewPage.dart';
import 'package:notepad_myscript_demo/manager/NotepadManager.dart';
import 'package:notepad_myscript_demo/manager/NotepadRealtime.dart';
import 'package:notepad_myscript_demo/manager/NotepadUtil.dart';
import 'package:notepad_myscript_demo/util/Toast.dart';

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
  var ptsList = List<FileSystemEntity>();

  var realtimeFilePath = '';

  var deleteFileSwich = false;

  var notepadState = NotepadState.Disconnected;

  StreamSubscription<NotepadStateEvent> _notepadStateSubscription;

  @override
  void initState() {
    super.initState();
    _requestListDocumentsDirectory();

    _notepadStateSubscription =
        sNotepadManager.notepadStateStream.listen(_onNotepadStateEvent);
  }

  @override
  Widget build(BuildContext context) {
    return buildScaffold(
      context,
      appBar: AppBar(
        title: Text('FileList'),
        actions: <Widget>[
          FlatButton(
            child: Text('RefreshList'),
            onPressed: () async {
              await _requestListDocumentsDirectory();
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
      notepadState: notepadState,
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
              if (!isInitMyscriptSuccess) {
                Toast.toast(context,
                    msg: 'Please initMyscript in "my-Settings"');
                return;
              }
              try {
                var filePath = await NewFilePath();
                Toast.toast(
                  context,
                  msg: 'filePath = $filePath',
                );
                var newController = await EditorController.create(filePath);
                Toast.toast(
                  context,
                  msg: 'EditorController.create(filePath)',
                );
                (await File(filePath).exists())
                    ? await newController.openPackage(filePath)
                    : await newController.createPackage(filePath);
                Toast.toast(
                  context,
                  msg: 'EditorController.openPackage/createPackage',
                );
                await newController.exportText();
                Toast.toast(
                  context,
                  msg: 'newController.exportText()',
                );
                await newController.clear();
                Toast.toast(
                  context,
                  msg: 'newController.clear()',
                );
                await _requestListDocumentsDirectory();
                Toast.toast(
                  context,
                  msg: 'CreateFile success',
                );
              } catch (e) {
                Toast.toast(
                  context,
                  msg: 'e = ${e.toString()}',
                );
                print('e = ${e.toString()}');
              }
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
          ptsList[index].path +
              (ptsList[index].path == realtimeFilePath ? '  【正在实时的笔记】' : ''),
          style: TextStyle(
            color: ptsList[index].path == realtimeFilePath
                ? Colors.red
                : Colors.black,
          ),
        ),
        trailing: deleteFileSwich ? Icon(Icons.delete_forever) : null,
        onTap: () async {
          if (deleteFileSwich) {
            File file = await File(ptsList[index].path);
            await file.deleteSync(recursive: true);
            await _requestListDocumentsDirectory();
          } else {
            if (!isInitMyscriptSuccess) {
              Toast.toast(context, msg: 'Please initMyscript in "my-Settings"');
              return;
            }
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => IInkViewPage(ptsList[index].path),
              ),
            );
          }
        },
      ),
      separatorBuilder: (context, index) => Divider(),
      itemCount: ptsList.length,
    );
  }

  _requestListDocumentsDirectory() async {
    var directory = await getApplicationDocumentsDirectory();
    setState(() => ptsList
      ..clear()
      ..addAll(directory.listSync())
      ..removeWhere((element) => !element.path.endsWith('.pts')));
    print('list.length = ${ptsList.length}');
    for (var file in ptsList) print('list.path = ${file.path}');
    print(
        'sRealtimeManager.realtimeFilePath = ${sRealtimeManager.fileStruct.filePath}');
    setState(() {
      realtimeFilePath = sRealtimeManager.fileStruct.filePath;
    });
  }

  _onNotepadStateEvent(NotepadStateEvent event) async {
    setState(() => notepadState = event.state);
  }
}
