import 'package:mp_flutter_chart/chart/mp/core/data/chart_data.dart';
import 'package:mp_flutter_chart/chart/mp/core/data_interfaces/i_radar_data_set.dart';
import 'package:mp_flutter_chart/chart/mp/core/entry/entry.dart';
import 'package:mp_flutter_chart/chart/mp/core/highlight/highlight.dart';

class RadarData extends ChartData<IRadarDataSet> {
  List<String> _labels;

  RadarData() : super();

  RadarData.fromList(List<IRadarDataSet> dataSets) : super.fromList(dataSets);

  List<String> get labels => _labels;

  set labels(List<String> value) {
    _labels = value;
  }

  @override
  Entry getEntryForHighlight(Highlight highlight) {
    return getDataSetByIndex(highlight.dataSetIndex)
        .getEntryForIndex(highlight.x.toInt());
  }
}
