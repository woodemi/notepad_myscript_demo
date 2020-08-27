import 'dart:math';
import 'DeviceSize.dart';

enum IINKPointerEventTypeFlutter { down, move, up, cancel }

String IINKPointerEventTypeFlutterDescription(
    IINKPointerEventTypeFlutter type) {
  switch (type) {
    case IINKPointerEventTypeFlutter.down:
      return 'down';
    case IINKPointerEventTypeFlutter.move:
      return 'move';
    case IINKPointerEventTypeFlutter.up:
      return 'up';
    case IINKPointerEventTypeFlutter.cancel:
      return 'cancel';
  }
  return 'down';
}

enum IINKPointerTypeFlutter { pen, touch, eraser }

String IINKPointerTypeFlutterDescription(IINKPointerTypeFlutter type) {
  switch (type) {
    case IINKPointerTypeFlutter.pen:
      return 'pen';
    case IINKPointerTypeFlutter.touch:
      return 'touch';
    case IINKPointerTypeFlutter.eraser:
      return 'eraser';
  }
  return 'pen';
}

class IINKPointerEventFlutter {
  IINKPointerEventTypeFlutter eventType;
  double x;
  double y;
  int t;
  double f;
  IINKPointerTypeFlutter pointerType;
  int pointerId;

  static final shared = IINKPointerEventFlutter(
    eventType: IINKPointerEventTypeFlutter.up,
    x: 0,
    y: 0,
    t: -1,
    f: 0,
    pointerType: IINKPointerTypeFlutter.pen,
    pointerId: -1,
  );

  IINKPointerEventFlutter clone({
    IINKPointerEventTypeFlutter eventType,
    double x,
    double y,
    int t,
    double f,
    IINKPointerTypeFlutter pointerType,
    int pointerId,
  }) =>
      IINKPointerEventFlutter(
        eventType: eventType ?? this.eventType,
        x: x ?? this.x,
        y: y ?? this.y,
        t: t ?? this.t,
        f: f ?? this.f,
        pointerType: pointerType ?? this.pointerType,
        pointerId: pointerId ?? this.pointerId,
      );

  IINKPointerEventFlutter({
    IINKPointerEventTypeFlutter eventType,
    double x,
    double y,
    int t,
    double f,
    IINKPointerTypeFlutter pointerType,
    int pointerId,
  }) {
    this.eventType = eventType;
    this.x = x;
    this.y = y;
    this.t = t;
    this.f = f;
    this.pointerType = pointerType;
    this.pointerId = pointerId;
  }

  Map<String, dynamic> toMap() => {
    'eventType': IINKPointerEventTypeFlutterDescription(eventType),
    'x': x,
    'y': y,
    't': t,
    'f': f,
    'pointerType': IINKPointerTypeFlutterDescription(pointerType),
    'pointerId': pointerId,
  };
}

enum MyscriptPenBrushType {
  FountainPen,
  CalligraphicBrush,
  Polyline,
}

class MyscriptPenBrush {
  static final brushs = {
    MyscriptPenBrushType.FountainPen: 'FountainPen',
    MyscriptPenBrushType.CalligraphicBrush: 'CalligraphicBrush',
    MyscriptPenBrushType.Polyline: 'Polyline',
  };

  MyscriptPenBrushType type;

  MyscriptPenBrush(MyscriptPenBrushType type) : this.type = type;

  MyscriptPenBrush.parse(String value) {
    this.type;
    MyscriptPenBrush.brushs.forEach((type, v) {
      if (v == value) this.type = type;
    });
  }

  String descriptions() => MyscriptPenBrush.brushs[type] ?? 'FountainPen';
}

class PenStyle {
  String color;
  double myscriptPenWidth;
  MyscriptPenBrush myscriptPenBrush;

  static final shared = PenStyle(
    color: '#313638',
    myscriptPenWidth: 0.3,
    myscriptPenBrush: MyscriptPenBrush(MyscriptPenBrushType.FountainPen),
  );

  PenStyle clone({
    String color,
    double myscriptPenWidth,
    MyscriptPenBrush myscriptPenBrush,
  }) =>
      PenStyle(
        color: color ?? this.color,
        myscriptPenWidth: myscriptPenWidth ?? this.myscriptPenWidth,
        myscriptPenBrush: myscriptPenBrush ?? this.myscriptPenBrush,
      );

  PenStyle({
    String color,
    double myscriptPenWidth,
    MyscriptPenBrush myscriptPenBrush,
  }) {
    this.color = color;
    this.myscriptPenWidth = myscriptPenWidth;
    this.myscriptPenBrush = myscriptPenBrush;
  }

  //ex：'color: #00ff38; -myscript-pen-width: 2.5; -myscript-pen-brush: FountainPen';
  PenStyle.parse(String value) {
    var arr = value.split('; ');
    arr.forEach((s) {
      var ss = s.split(': ');
      if (ss.length == 2) {
        switch (ss[0]) {
          case 'color':
            color = ss[1];
            break;
          case '-myscript-pen-width':
            myscriptPenWidth = double.parse(ss[1]);
            break;
          case '-myscript-pen-brush':
            myscriptPenBrush = MyscriptPenBrush.parse(ss[1]);
            break;
        }
      }
    });
  }

  String fromat() {
    var style = {
      if (color != null) 'color': color,
      if (myscriptPenWidth != null) '-myscript-pen-width': myscriptPenWidth,
      if (myscriptPenBrush != null)
        '-myscript-pen-brush': myscriptPenBrush.descriptions(),
    };
    return style.entries.map((e) => '${e.key}: ${e.value}').join('; ');
  }
}

//  Stroke Myxcript-1.2.* 解析
class Stroke {
  final int timestamp;
  final List<IINKPointerEventFlutter> pointers;

  Stroke.fromMap(Map map)
      : timestamp = DateTime.parse(map['timestamp']).millisecondsSinceEpoch,
        pointers = _getPointersOfStroke(map);

  static List<IINKPointerEventFlutter> _getPointersOfStroke(Map stroke) {
    var pointerEventsOfStroke = List<IINKPointerEventFlutter>();

    var timestamp = stroke['timestamp'] as String;
    int currentTimeinterval = DateTime.parse(timestamp).millisecondsSinceEpoch;

    final xs = stroke['X'] as List<dynamic>;
    final ys = stroke['Y'] as List<dynamic>;
    final fs = stroke['F'] as List<dynamic>;
    final ts = stroke['T'] as List<dynamic>;

    var minNum = min(xs.length, ys.length);
    minNum = min(minNum, fs.length);
    minNum = min(minNum, ts.length);

    for (var i = 0; i < minNum; i++) {
      var eventType = i == 0
          ? IINKPointerEventTypeFlutter.down
          : i == minNum - 1
              ? IINKPointerEventTypeFlutter.up
              : IINKPointerEventTypeFlutter.move;
      final pointerEventFlutter = IINKPointerEventFlutter(
        eventType: eventType,
        x: double.parse('${xs[i]}') * ExportScale_x,
        y: double.parse('${ys[i]}') * ExportScale_x,
        t: currentTimeinterval + int.parse('${ts[i]}'),
        f: double.parse('${fs[i]}'),
        pointerType: IINKPointerTypeFlutter.pen,
        pointerId: -1,
      );
      pointerEventsOfStroke.add(pointerEventFlutter);
    }
    return pointerEventsOfStroke;
  }
}

class Word {
  var strokes = List<Stroke>();

  Word.fromMap(Map map) {
    var items = (map['strokes'] as List);
    if (items == null) return;
    strokes = items.map((m) => Stroke.fromMap(m)).toList();
  }
}
