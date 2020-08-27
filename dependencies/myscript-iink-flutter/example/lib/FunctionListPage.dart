import 'package:flutter/material.dart';
import 'package:myscript_iink_example/sizes.dart';

class FunctionItem {
  String title;
  String subTitle;

  FunctionItem(String title, {String subTitle}) {
    this.title = title;
    this.subTitle = subTitle;
  }
}

class FunctionListWidget extends Dialog {
  List<FunctionItem> items;
  Function(String) call;

  FunctionListWidget({
    Key key,
    this.items,
    this.call,
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
            subtitle: items[index].subTitle != null
                ? Text(items[index].subTitle)
                : null,
            onTap: () {
              Navigator.pop(context);
              call(items[index].title);
            },
          );
        },
        separatorBuilder: (context, index) => Divider(),
      ),
    );
  }
}
