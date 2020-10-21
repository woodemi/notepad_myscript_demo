import 'dart:async';
import 'dart:core';
import 'dart:typed_data';
import 'dart:ui';

import 'package:notepad_core/notepad_core.dart';
import 'package:notepad_myscript_demo/manager/NotepadUtil.dart';

final sNotepadManager = NotepadManager._internal();

class NotepadManager implements NotepadClientCallback {
  static String get TAG => 'NotepadManager';

  /*
  * 扫描到新蓝牙 noti
  */
  final Stream<NotepadScanResult> scanResultStream =
      notepadConnector.scanResultStream;

  final _notepadEventMessageStreamController =
      StreamController<NotepadEvent>.broadcast();

  /*
  * 事件上报 noti
  */
  Stream<NotepadEvent> get notepadEventMessageStream =>
      _notepadEventMessageStreamController.stream;

  /*
  * receive实时点位 noti
  */
  Stream<NotePenPointer> get notepadSyncPointerStream =>
      _notepadSyncPointerStreamController.stream;

  final _notepadSyncPointerStreamController =
      StreamController<NotePenPointer>.broadcast();

  /*
   *  导入离线笔记
   */
  bool get isImporting => (_progress.memoCount != 0 &&
      _progress.memoCount != _progress.importedCount);

  //  列表进度 noti
  final _progressStreamController =
      StreamController<ImportProgress>.broadcast();

  Stream<ImportProgress> get progressStream => _progressStreamController.stream;

  ImportProgress _progress = ImportProgress.internal(0, 0);

  ImportProgress get progress => _progress;

  _setProgress(ImportProgress p) {
    _progress = p;
    _progressStreamController.add(progress);
  }

  //  正在导入笔记的进度 noti
  final _notepadImportProgressStreamController =
      StreamController<int>.broadcast();

  Stream<int> get notepadImportProgressStream =>
      _notepadImportProgressStreamController.stream;

  /*
  * 连接状态 noti
  */
  Stream<NotepadStateEvent> get notepadStateStream =>
      _notepadStateStreamController.stream;

  final _notepadStateStreamController =
      StreamController<NotepadStateEvent>.broadcast();

  NotepadState _notepadState = NotepadState.Disconnected;

  NotepadState get notepadState => _notepadState;

  //  缓存当前已连接的设备
  NotepadScanResult _currentDevice;

  NotepadScanResult get connectedDevice =>
      _notepadState == NotepadState.Disconnected ? null : _currentDevice;

  //  当前设备的模式
  var deviceMode = NotepadMode.Common;

  NotepadClient _notepadClient;

  NotepadManager._internal() {
    notepadConnector.connectionChangeHandler = handleConnectionChange;
  }

  var tempHashCode = 0;

  handleConnectionChange(
    NotepadClient client,
    NotepadConnectionState state,
  ) async {
    print('handleConnectionChange $client ${state.value}');

    //  TODO FIX 不可频繁连接
    if (state == NotepadConnectionState.connected &&
        tempHashCode == client.hashCode) {
      Timer(Duration(seconds: 2), () {
        tempHashCode = 0;
      });
      return;
    }

    if (state == NotepadConnectionState.connected)
      tempHashCode = client.hashCode;

    switch (state) {
      case NotepadConnectionState.awaitConfirm:
        _notepadState = NotepadState.AwaitConfirm;
        break;
      case NotepadConnectionState.connected:
        _notepadClient = client;
        _notepadClient.callback = this;

        try {
          await setMode(NotepadMode.Sync);
          await setDeviceDate(DateTime.now().millisecond);
        } catch (e) {
          print('Connection config error: $e');
        }
        _notepadState = NotepadState.Connected;
        await stopScan();
        break;
      case NotepadConnectionState.disconnected:
        _notepadState = NotepadState.Disconnected;
        break;
      case NotepadConnectionState.connecting:
        _notepadState = NotepadState.Connecting;
        break;
      default:
        break;
    }
    _notepadStateStreamController.add(NotepadStateEvent(_notepadState));
  }

  @override
  void handleEvent(NotepadEvent notepadEvent) {
    _notepadEventMessageStreamController.add(notepadEvent);
  }

  @override
  void handlePointer(List<NotePenPointer> list) {
    list.forEach((pointer) {
      _notepadSyncPointerStreamController.add(pointer);
    });
  }

  startScan() => notepadConnector.startScan();

  stopScan() => notepadConnector.stopScan();

  int lastConnectTime = 0;

  connect(NotepadScanResult scanResult, [Uint8List authToken]) {
    if (notepadState == NotepadState.Disconnected) {
      if (nowDate() - lastConnectTime > 3000) {
        lastConnectTime = nowDate();
        _currentDevice = scanResult;
        notepadConnector.connect(scanResult, authToken);
      }
    }
  }

  disconnect() => notepadConnector.disconnect();

  Future<void> setMode(NotepadMode mode) async {
    deviceMode = mode;
    return await _notepadClient.setMode(mode);
  }

  Future<void> claimAuth() async {
    await _notepadClient.claimAuth();
  }

  Future<void> disclaimAuth() async {
    await _notepadClient.disclaimAuth();
  }

  Size getDeviceSize() {
    return _notepadClient.getDeviceSize();
  }

  Future<String> getDeviceName() async {
    return await _notepadClient.getDeviceName();
  }

  Future<void> setDeviceName(String name) async {
    await _notepadClient.setDeviceName(name);
  }

  Future<BatteryInfo> getBatteryInfo() async {
    return await _notepadClient.getBatteryInfo();
  }

  Future<int> getDeviceDate() async {
    return await _notepadClient.getDeviceDate();
  }

  Future<void> setDeviceDate(int date) async {
    await _notepadClient.setDeviceDate(date);
  }

  //  minute
  Future<int> getAutoLockTime() async {
    return await _notepadClient.getAutoLockTime();
  }

  //  minute
  Future<void> setAutoLockTime(int time) async {
    await _notepadClient.setAutoLockTime(time);
  }

  Future<MemoSummary> getMemoSummary() async {
    return await _notepadClient.getMemoSummary();
  }

  Future<MemoInfo> getMemoInfo() async {
    return await _notepadClient.getMemoInfo();
  }

  Future<MemoData> importStackTopMemo() async {
    return await _notepadClient.importMemo((progress) {
      print('progress $progress');
      _notepadImportProgressStreamController.add(progress);
    });
  }

  Future<void> importAllMemo() async {
    var memoSummary = await getMemoSummary();
    if (isImporting || memoSummary.memoCount == 0) return;
    _setProgress(ImportProgress.internal(memoSummary.memoCount, 0));
    do {
      var memoData = await sNotepadManager.importStackTopMemo();

      await handleImportMemoData(memoData);

      await sNotepadManager.deleteMemo();
      _setProgress(_progress.clone(
        importCount: _progress.importedCount + 1,
      ));
    } while (_progress.importedCount < _progress.memoCount);
    print('import All memo finished');
  }

  Future<void> deleteMemo() async {
    await _notepadClient.deleteMemo();
  }

  Future<VersionInfo> getVersionInfo() async {
    return await _notepadClient.getVersionInfo();
  }

  Future<void> upgrade(
    Uint8List upgradeBlob,
    Version version,
    void progress(int),
  ) async {}
}
