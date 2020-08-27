import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:notepad_core/notepad_core.dart';
import 'package:http/http.dart' as http;
import 'package:notepad_myscript_demo/manager/NotepadManager.dart';
import 'package:notepad_myscript_demo/util/FunctionListWidget.dart';

class NotepadDetailPage extends StatefulWidget {
  NotepadScanResult scanResult;

  NotepadDetailPage(this.scanResult);

  @override
  State<StatefulWidget> createState() => _NotepadDetailPageState();
}

final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

_toast(String msg) => _scaffoldKey.currentState
    .showSnackBar(SnackBar(content: Text(msg), duration: Duration(seconds: 2)));

class _NotepadDetailPageState extends State<NotepadDetailPage> {
  //  motepad-core的方法集
  var notepadList = List<FunctionItem>();

  @override
  void initState() {
    super.initState();
    initFunctionList();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text('${widget.scanResult.deviceId}'),
      ),
      body: ListView.separated(
        itemCount: notepadList.length,
        itemBuilder: (context, index) {
          return ListTile(
            dense: true,
            title: Text(
              notepadList[index].title,
              style: TextStyle(
                color: Colors.black,
                fontSize: 15.5,
                decorationColor: Colors.white,
                fontWeight: FontWeight.w400,
              ),
            ),
            subtitle: notepadList[index].content != null
                ? Text(notepadList[index].content)
                : null,
            onTap: notepadList[index].callBack,
          );
        },
        separatorBuilder: (context, index) => Divider(),
      ),
    );
  }

  /*-----------------------------------------------------------------------
  *
  * notepad-core methods
  *
  * -----------------------------------------------------------------------*/
  initFunctionList() {
    setState(() {
      notepadList = [
        FunctionItem('connect', callBack: connect),
        FunctionItem('disconnect', callBack: disconnect),
        FunctionItem('setMode', callBack: setMode),
        FunctionItem('claimAuth', callBack: claimAuth),
        FunctionItem('disclaimAuth', callBack: disClaimAuth),
        FunctionItem('getDeviceSize', callBack: getDeviceSize),
        FunctionItem('getDeviceName', callBack: getDeviceName),
        FunctionItem('setDeviceName', callBack: setDeviceName),
        FunctionItem('getBatteryInfo', callBack: getBatteryInfo),
        FunctionItem('getDeviceDate', callBack: getDeviceDate),
        FunctionItem('setDeviceDate', callBack: setDeviceDate),
        FunctionItem('getAutoLockTime', callBack: getAutoLockTime),
        FunctionItem('setAutoLockTime', callBack: setAutoLockTime),
        FunctionItem('getMemoSummary', callBack: getMomoSummary),
        FunctionItem('getMemoInfo', callBack: getMemoInfo),
        FunctionItem('importMemo', callBack: importStackTopMemo),
        FunctionItem('deleteMemo', callBack: deleteMemo),
        FunctionItem('getVersionInfo', callBack: getVersionInfo),
        FunctionItem('upgrade', callBack: upgrade),
      ];
    });
  }

  void connect() {
    sNotepadManager.connect(
      widget.scanResult,
      Uint8List.fromList([0x00, 0x00, 0x00, 0x02]),
    );
    _toast('request connect');
  }

  void disconnect() {
    notepadConnector.disconnect();
    _toast('disconnect success');
  }

  Future<void> setMode() async {
    await sNotepadManager.setMode(NotepadMode.Sync);
    _toast('setMode success');
  }


  Future claimAuth() async {
    await sNotepadManager.claimAuth();
    _toast('claimAuth success');
  }

  Future disClaimAuth() async {
    await sNotepadManager.disclaimAuth();
    _toast('disclaimAuth success');
  }

  void getDeviceSize() {
    var size = sNotepadManager.getDeviceSize();
    _toast('device size = $size');
  }

  Future getDeviceName() async {
    _toast('DeviceName: ${await sNotepadManager.getDeviceName()}');
  }

  Future setDeviceName() async {
    await sNotepadManager.setDeviceName('abc');
    _toast('New DeviceName: ${await sNotepadManager.getDeviceName()}');
  }

  Future getBatteryInfo() async {
    BatteryInfo battery = await sNotepadManager.getBatteryInfo();
    _toast(
        'battery.percent = ${battery.percent}  battery.charging = ${battery.charging}');
  }

  Future getDeviceDate() async {
    var date = await sNotepadManager.getDeviceDate();
    _toast('date = ${date}');
  }

  Future setDeviceDate() async {
    await sNotepadManager.setDeviceDate(0); // second
    var date = await sNotepadManager.getDeviceDate();
    _toast('new DeivceDate = ${date}');
  }

  Future getAutoLockTime() async {
    _toast('AutoLockTime = ${await sNotepadManager.getAutoLockTime()}');
  }

  Future setAutoLockTime() async {
    await sNotepadManager.setAutoLockTime(10);
    _toast('new AutoLockTime = ${await sNotepadManager.getAutoLockTime()}');
  }

  Future getMomoSummary() async {
    var memoSummary = await sNotepadManager.getMemoSummary();
    _toast('getMemoSummary ${memoSummary.toString()}');
  }

  Future getMemoInfo() async {
    var memoInfo = await sNotepadManager.getMemoInfo();
    _toast('getMemoInfo ${memoInfo.toString()}');
  }

  Future importStackTopMemo() async {
    var memoData = await sNotepadManager.importStackTopMemo();
    _toast('importStackTopMemo finish');
    memoData.pointers.forEach((p) async {
      print('memoData x = ${p.x}\ty = ${p.y}\tt = ${p.t}\tp = ${p.p}');
    });
  }

  Future deleteMemo() async {
    await sNotepadManager.deleteMemo();
    _toast('deleteMemo');
  }

  Future upgrade() async {
    var upgradeBlob = await _loadUpgradeFile(Version(1, 0, 0));
    await sNotepadManager.upgrade(upgradeBlob, Version(0xFF, 0xFF, 0xFF),
        (progress) {
      print('upgrade progress $progress');
    });
  }

  Future getVersionInfo() async {
    VersionInfo version = await sNotepadManager.getVersionInfo();
    _toast(
        'version.hardware = ${version.hardware.major}  version.software = ${version.hardware.minor} version.software = ${version.software.major} version.software = ${version.software.minor} version.software = ${version.software.patch}');
  }

  Future<Uint8List> _loadUpgradeFile(Version version) async {
    var userServiceUrl = await _getUserServiceUrl();
    var appUrl = await _getAppUrl(userServiceUrl, version);
    return (await http.get(appUrl)).bodyBytes;
  }

  Future<String> _getUserServiceUrl() async {
    var response = await http.get('https://service.36notes.com/v2/config/info');
    return json.decode(response.body)['data']['entities'][0]['userServiceUrl'];
  }

  Future<String> _getAppUrl(String userServiceUrl, Version version) async {
    var appVer = '${version.major}.${version.minor ?? 0}.${version.patch ?? 0}';
    var response =
        await http.get('$userServiceUrl/config/nxpUpdate?appVer=$appVer');
    return json.decode(response.body)['data']['appUrl'];
  }
}
