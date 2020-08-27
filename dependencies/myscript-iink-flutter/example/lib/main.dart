import 'dart:io';

import 'package:flutter/material.dart';
import 'package:myscript_iink_example/ConfigEngine.dart';
import 'package:myscript_iink_example/IInkViewPage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:myscript_iink/EditorController.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  var list = List<FileSystemEntity>();

  @override
  void initState() {
    super.initState();
    _requestListDocumentsDirectory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plugin example app'),
        actions: <Widget>[
          FlatButton(
            child: Text('Create'),
            onPressed: () async {
              var directory = await getApplicationDocumentsDirectory();
              var filePath =
                  '${directory.path}/${DateTime.now().millisecondsSinceEpoch}.pts';
              var newController = await EditorController.create(filePath);
              (await File(filePath).exists())
                  ? await newController.openPackage(filePath)
                  : await newController.createPackage(filePath);
              await newController.clear();
              await newController.close();

              await _requestListDocumentsDirectory();
            },
          ),
          FlatButton(
            child: Text('Settings'),
            onPressed: () {
              Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => ConfigEngine()));
            },
          )
        ],
      ),
      body: ListView.separated(
        itemBuilder: (context, index) => ListTile(
          title: Text(list[index].path),
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => IInkViewPage(list[index].path)));
          },
        ),
        separatorBuilder: (context, index) => Divider(),
        itemCount: list.length,
      ),
    );
  }

  Widget centerText(String text) => Center(child: Text(text));

  _requestListDocumentsDirectory() async {
    var directory = await getApplicationDocumentsDirectory();
    setState(() => list
      ..clear()
      ..addAll(directory.listSync()));
  }
}
