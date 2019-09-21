import 'package:mp_flutter_chart/chart/mp/core/entry/base_entry.dart';
import 'dart:ui' as ui;

class Entry extends BaseEntry {
  double _x = 0;

  Entry({double x, double y, ui.Image icon, Object data})
      : this._x = x,
        super(y: y, icon: icon, data: data);

  Entry copy() {
    Entry e = Entry(x: _x, y: y, data: mData);
    return e;
  }

  double get x => _x;

  set x(double value) {
    _x = value;
  }
}
