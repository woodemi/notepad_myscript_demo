import 'dart:async';

import 'package:flutter/services.dart';

const MYSCRIPT_IINK_PACKAGE = 'myscript_iink';

class MyscriptIink {
  static const MethodChannel _channel = const MethodChannel(MYSCRIPT_IINK_PACKAGE);

  static Future<void> initMyscript() async {
    await _channel.invokeMethod('initMyscript', {});
  }

  static Future<void> createEditorControllerChannel(String channelName) async {
    await _channel.invokeMethod('createEditorControllerChannel', {'channelName': channelName});
  }

  static Future<void> closeEditorControllerChannel(String channelName) async {
    await _channel.invokeMethod('closeEditorControllerChannel', {'channelName': channelName});
  }

  static Future<void> setEngineConfiguration_Language(String lang) async {
    await _channel.invokeMethod('setEngineConfiguration_Language', {'lang': lang});
  }

  //  TODO add get EngineConfigurationInfo(比如：language)
}
