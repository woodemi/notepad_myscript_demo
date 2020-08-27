import 'package:flutter/material.dart';
import 'package:notepad_myscript_demo/util/sizes.dart';

class FunctionItem {
  String title;
  String content;
  VoidCallback callBack;

  FunctionItem(String title, {String content, VoidCallback callBack}) {
    this.title = title;
    this.callBack = callBack;
    this.content = content;
  }
}

class FunctionListWidget extends Dialog {
  List<FunctionItem> items;

  FunctionListWidget({
    Key key,
    this.items,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      margin: EdgeInsets.only(
        top: (ScreenHeight - ScreenWidth) * 0.5,
        left: 30,
        bottom: (ScreenHeight - ScreenWidth) * 0.5,
        right: 30,
      ),
      clipBehavior: Clip.hardEdge,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
      child: Column(
        children: <Widget>[
          Container(
            padding: EdgeInsets.all(10),
            child: Text('FunctionList', style: TextStyle(color: Colors.red)),
          ),
          Expanded(child: _buildContainer()),
        ],
      ),
    );
  }

  Container _buildContainer() {
    return Container(
      color: Colors.white,
      margin: EdgeInsets.all(0),
      child: ListView.separated(
        itemCount: items.length,
        itemBuilder: (context, index) {
          return ListTile(
            dense: true,
            title: Text(
              items[index].title,
              style: TextStyle(
                color: Colors.black,
                fontSize: 15.5,
                decorationColor: Colors.white,
                fontWeight: FontWeight.w400,
              ),
            ),
            subtitle: items[index].content != null
                ? Text(items[index].content)
                : null,
            onTap: () {
              Navigator.pop(context);
              items[index].callBack();
            },
          );
        },
        separatorBuilder: (context, index) => Divider(),
      ),
    );
  }
}
