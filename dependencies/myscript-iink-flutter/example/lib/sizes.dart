import 'dart:ui';

double get ScreenWidth => window.physicalSize.width / window.devicePixelRatio;
double get ScreenHeight => window.physicalSize.height / window.devicePixelRatio;

double get DialogWidth => ScreenWidth / 17 * 13;
double get DialogHeight => ScreenWidth;