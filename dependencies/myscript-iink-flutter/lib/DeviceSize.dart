import 'dart:math';
import 'dart:ui';
import 'dart:io';

Size get _ScreenPhysicalSize => window.physicalSize;
double get _ScreenDevicePixelRatio =>window.devicePixelRatio;
final DeviceWidth_mm = 157.5;
final EditArea_xOffsetScale = 800.0 / 14800.0;

const devicePixels = Size(14800, 21000);
final _paintScale = min(_ScreenPhysicalSize.width / devicePixels.width,
    _ScreenPhysicalSize.height / devicePixels.height);

Size paintSize = devicePixels * _paintScale;
double get viewScale {  // renderer的参数
  if (Platform.isAndroid) {
    return _paintScale;
  } else if (Platform.isIOS) {
    return _paintScale / _ScreenDevicePixelRatio;
  }
  return _paintScale;
}

double Renderer_xDpi = 2610; // renderer的参数（使用设备的）
double Renderer_yDpi = 2540; // renderer的参数（使用设备的）

// TODO Fix
double ExportScale_x = 102.755909 * viewScale;  //  Renderer_xDpi / 25.4 * _paintScale;
double ExportScale_y = 102.755909 * viewScale;  //  Renderer_yDpi / 25.4 * _paintScale;

int maxStrokeLength = 5000;