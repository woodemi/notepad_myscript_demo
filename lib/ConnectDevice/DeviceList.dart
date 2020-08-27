import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:notepad_core/notepad_core.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:notepad_myscript_demo/ConnectDevice/NotepadDetailPage.dart';
import 'package:notepad_myscript_demo/manager/NotepadManager.dart';
import 'package:notepad_myscript_demo/util/permission.dart';

final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

toast(String msg) => _scaffoldKey.currentState
    .showSnackBar(SnackBar(content: Text(msg), duration: Duration(seconds: 2)));

class DeviceList extends StatefulWidget {
  DeviceList();

  @override
  State<StatefulWidget> createState() => _DeviceListState();
}

class _DeviceListState extends State<DeviceList> {
  StreamSubscription<NotepadScanResult> _subscription;

  @override
  void initState() {
    super.initState();
    notepadConnector.bluetoothChangeHandler = _handleBluetoothChange;
    _subscription = notepadConnector.scanResultStream.listen((result) {
      if (!_scanResults.any((r) => r.deviceId == result.deviceId)) {
        setState(() => _scanResults.add(result));
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    notepadConnector.bluetoothChangeHandler = null;
    _subscription?.cancel();
  }

  void _handleBluetoothChange(BluetoothState state) {
    toast('_handleBluetoothChange ${state.value}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(title: Text('DeviceList')),
      body: Column(
        children: <Widget>[
          FutureBuilder(
            future: notepadConnector.isBluetoothAvailable(),
            builder: (context, snapshot) {
              var available = snapshot.data?.toString() ?? '...';
              return Text('Bluetooth init: $available');
            },
          ),
          _buildButtons(),
          Divider(color: Colors.blue),
          _buildListView(),
        ],
      ),
    );
  }

  Widget _buildButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        RaisedButton(
          child: Text('startScan'),
          onPressed: () async {
            print('startScan');
            var b = Platform.isAndroid
                ? await checkAndRequest(PermissionGroup.location)
                : true;
            print('startScan');
            if (b) sNotepadManager.startScan();
          },
        ),
        RaisedButton(
          child: Text('stopScan'),
          onPressed: () {
            sNotepadManager.stopScan();
          },
        ),
      ],
    );
  }

  var _scanResults = List<NotepadScanResult>();

  Widget _buildListView() {
    return Expanded(
      child: ListView.separated(
        itemBuilder: (context, index) => ListTile(
          title:
              Text('${_scanResults[index].name}(${_scanResults[index].rssi})'),
          subtitle: Text(_scanResults[index].deviceId),
          onTap: () {
            setState(() {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => NotepadDetailPage(_scanResults[index]),
                ),
              );
            });
          },
        ),
        separatorBuilder: (context, index) => Divider(),
        itemCount: _scanResults.length,
      ),
    );
  }
}
