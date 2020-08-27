import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:myscript_iink/EditorController.dart';
import 'package:myscript_iink_example/FunctionListPage.dart';
import 'package:myscript_iink/myscript_iink.dart';
import 'package:myscript_iink_example/Toast.dart';

class ConfigEngine extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _ConfigEngineState();
}

class _ConfigEngineState extends State<ConfigEngine> {
  var functionList = [
    FunctionItem('setEngineConfiguration_Language', subTitle: 'Current-Language: zh-CN'),
    //  TODO add get EngineConfigurationInfo(比如：language)
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Config Engine')),
      body: ListView.separated(
        itemCount: functionList.length,
        itemBuilder: (context, index) {
          return ListTile(
            dense: true,
            title: Text(
              functionList[index].title,
              style: TextStyle(
                color: Colors.black,
                fontSize: 15.5,
                decorationColor: Colors.white,
                fontWeight: FontWeight.w400,
              ),
            ),
            subtitle: functionList[index].subTitle != null
                ? Text(functionList[index].subTitle)
                : null,
            onTap: () => _functionCall(functionList[index].title),
          );
        },
        separatorBuilder: (context, index) => Divider(),
      ),
    );
  }

  _functionCall(String title) async {
    switch (title) {
      case 'setEngineConfiguration_Language':
        await MyscriptIink.setEngineConfiguration_Language('zh_CN');
        Toast.toast(context, msg: 'setEngineConfiguration_Language success');
        break;
      default:
        break;
    }
  }

}
