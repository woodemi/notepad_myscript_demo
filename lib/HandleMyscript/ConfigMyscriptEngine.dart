import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:myscript_iink/myscript_iink.dart';
import 'package:notepad_myscript_demo/util/FunctionListWidget.dart';
import 'package:notepad_myscript_demo/util/Toast.dart';

var isInitMyscriptSuccess = false;

class ConfigMyscriptEngine extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _ConfigMyscriptEngineState();
}

class _ConfigMyscriptEngineState extends State<ConfigMyscriptEngine> {
  var functionList = List<FunctionItem>();

  initFunctionList() {
    setState(() {
      functionList = [
        FunctionItem(
          'initMyscript',
          content: 'initMyscript before use myscript',
          callBack: () async {
            if (isInitMyscriptSuccess) {
              Toast.toast(context, msg: 'You had init-Myscript');
              return;
            }
            try {
              Toast.toast(context, msg: 'initMyscript success');
              var startDate = DateTime.now().millisecondsSinceEpoch;
              await MyscriptIink.initMyscript();
              var endDate = DateTime.now().millisecondsSinceEpoch;
              isInitMyscriptSuccess = true;
              Toast.toast(context,
                  msg: 'initMyscript success, 用时${endDate - startDate}');
            } catch (e) {
              Toast.toast(context, msg: 'initMyscript faile, ${e.toString()}');
            }
          },
        ),
        FunctionItem(
          'setEngineLanguage: Current-Language zh-CN',
          content: 'Config MyScript Engine before create file(pts)',
          callBack: () async {
            if (!isInitMyscriptSuccess) {
              Toast.toast(
                context,
                msg: 'Please initMyscript in "my-Settings"',
              );
              return;
            }
            await MyscriptIink.setEngineConfiguration_Language('zh_CN');
            Toast.toast(context,
                msg: 'setEngineConfiguration_Language success');
          },
        ),
        //  TODO add get EngineConfigurationInfo(比如：language)
      ];
    });
  }

  @override
  void initState() {
    super.initState();
    initFunctionList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Config MyScript Engine')),
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
            subtitle: functionList[index].content != null
                ? Text(functionList[index].content)
                : null,
            onTap: functionList[index].callBack,
          );
        },
        separatorBuilder: (context, index) => Divider(),
      ),
    );
  }
}
