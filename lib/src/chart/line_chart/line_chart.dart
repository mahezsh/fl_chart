import 'package:fl_chart/fl_chart.dart';
import 'package:fl_chart/src/chart/base/base_chart/base_chart_data.dart';
import 'package:fl_chart/src/chart/base/base_chart/base_chart_painter.dart';
import 'package:fl_chart/src/chart/base/base_chart/touch_input.dart';
import 'package:fl_chart/src/chart/base/base_chart_data_tween.dart';
import 'package:fl_chart/src/utils/utils.dart';
import 'package:flutter/cupertino.dart';

import 'line_chart_data.dart';
import 'line_chart_painter.dart';

class LineChart extends StatelessWidget {
  final LineChartData data;
  final Duration swapAnimationDuration;
  final bool handleTouches;

  const LineChart(this.data, {
    this.swapAnimationDuration = const Duration(milliseconds: 150),
    this.handleTouches = true,
  }) : super();

  @override
  Widget build(BuildContext context) {
    if (handleTouches) {
      return _LineChartDefaultTouches(data, swapAnimationDuration,);
    } else {
      return _LineChartWidget(data, swapAnimationDuration,);
    }
  }
}

class _LineChartWidget extends ImplicitlyAnimatedWidget {
  final LineChartData data;

  const _LineChartWidget(this.data,
    Duration swapAnimationDuration,) : super(duration: swapAnimationDuration);

  @override
  _LineChartWidgetState createState() => _LineChartWidgetState();
}

class _LineChartWidgetState extends AnimatedWidgetBaseState<_LineChartWidget> {
  /// we handle under the hood animations (implicit animations) via this tween,
  /// it lerps between the old [BaseChartData] to the new one.
  BaseChartDataTween _baseChartDataTween;

  TouchHandler _touchHandler;

  LineChartData showingData;

  final GlobalKey _chartKey = GlobalKey();

  @override
  Widget build(BuildContext context) {

    var chartSize = getDefaultSize(context);
    if (_chartKey.currentContext != null) {
      final RenderBox containerRenderBox =
      _chartKey.currentContext.findRenderObject();
      chartSize = containerRenderBox.size;
    }

    return GestureDetector(
      onLongPressStart: (d) {
        final LineTouchResponse response =
        _touchHandler?.handleTouch(FlLongPressStart(d.localPosition), chartSize);
        if (response != null &&
          widget.data.lineTouchData != null &&
          widget.data.lineTouchData.touchCallback != null) {
          widget.data.lineTouchData.touchCallback(response);
        }
      },
      onLongPressEnd: (d) async {
        final LineTouchResponse response =
        _touchHandler?.handleTouch(FlLongPressEnd(d.localPosition), chartSize);
        if (response != null &&
          widget.data.lineTouchData != null &&
          widget.data.lineTouchData.touchCallback != null) {
          widget.data.lineTouchData.touchCallback(response);
        }
      },
      onLongPressMoveUpdate: (d) {
        final LineTouchResponse response = _touchHandler?.handleTouch(
          FlLongPressMoveUpdate(d.localPosition), chartSize);
        if (response != null &&
          widget.data.lineTouchData != null &&
          widget.data.lineTouchData.touchCallback != null) {
          widget.data.lineTouchData.touchCallback(response);
        }
      },
      onPanCancel: () async {
        final LineTouchResponse response =
        _touchHandler?.handleTouch(FlPanEnd(Offset.zero), chartSize);
        if (response != null &&
          widget.data.lineTouchData != null &&
          widget.data.lineTouchData.touchCallback != null) {
          widget.data.lineTouchData.touchCallback(response);
        }
      },
      onPanEnd: (DragEndDetails details) async {
        final LineTouchResponse response =
        _touchHandler?.handleTouch(FlPanEnd(Offset.zero), chartSize);
        if (response != null &&
          widget.data.lineTouchData != null &&
          widget.data.lineTouchData.touchCallback != null) {
          widget.data.lineTouchData.touchCallback(response);
        }
      },
      onPanDown: (DragDownDetails details) {
        final LineTouchResponse response =
        _touchHandler?.handleTouch(FlPanStart(details.localPosition), chartSize);
        if (response != null &&
          widget.data.lineTouchData != null &&
          widget.data.lineTouchData.touchCallback != null) {
          widget.data.lineTouchData.touchCallback(response);
        }
      },
      onPanUpdate: (DragUpdateDetails details) {
        final LineTouchResponse response = _touchHandler?.handleTouch(
          FlPanMoveUpdate(details.localPosition), chartSize);
        if (response != null &&
          widget.data.lineTouchData != null &&
          widget.data.lineTouchData.touchCallback != null) {
          widget.data.lineTouchData.touchCallback(response);
        }
      },
      child: CustomPaint(
        key: _chartKey,
        size: getDefaultSize(context),
        painter:
        LineChartPainter(_baseChartDataTween.evaluate(animation), widget.data, (touchHandler) {
          _touchHandler = touchHandler;
        }),
      ),
    );
  }

  @override
  void forEachTween(visitor) {
    _baseChartDataTween = visitor(
      _baseChartDataTween,
      widget.data,
        (dynamic value) => BaseChartDataTween(begin: value),
    );
  }
}

class _LineChartDefaultTouches extends StatefulWidget {

  final LineChartData data;
  final Duration swapAnimationDuration;

  const _LineChartDefaultTouches(this.data, this.swapAnimationDuration,) : super();

  @override
  State<StatefulWidget> createState() => _LineChartDefaultTouchesState();

}

class _LineChartDefaultTouchesState extends State<_LineChartDefaultTouches> {

  List<MapEntry<int, List<FlSpot>>> showingTooltips = [];
  Map<int, List<int>> showingIndicators = {};

  @override
  Widget build(BuildContext context) {
    return _LineChartWidget(
      widget.data.copyWith(
        lineTouchData: widget.data.lineTouchData.copyWith(
          touchCallback: (LineTouchResponse touchResponse) {
            if (widget.data.lineTouchData.touchCallback != null )  {
              widget.data.lineTouchData.touchCallback(touchResponse);
            }

            if (touchResponse.touchInput is FlPanStart ||
              touchResponse.touchInput is FlPanMoveUpdate ||
              touchResponse.touchInput is FlLongPressStart ||
              touchResponse.touchInput is FlLongPressMoveUpdate
            ) {
              setState(() {
                showingTooltips.clear();
                showingTooltips.add(MapEntry(0, touchResponse.spots.map((touchedSpot) => touchedSpot.spot).toList()));

                showingIndicators.clear();
                for (int i = 0; i < touchResponse.spots.length; i++) {
                  final touchedSpot = touchResponse.spots[i];
                  final barPos = touchedSpot.barDataPosition;
                  showingIndicators[barPos] = [touchedSpot.spotIndex];
                }
              });
            } else {
              setState(() {
                showingTooltips.clear();
                showingIndicators.clear();
              });
            }
          }
        ),
        showingTooltipIndicators: showingTooltips,
        lineBarsData: widget.data.lineBarsData.map((barData) {
          final index = widget.data.lineBarsData.indexOf(barData);
          return barData.copyWith(
            showingIndicators: showingIndicators[index] ?? [],
          );
        }).toList(),
      ),
      widget.swapAnimationDuration,
    );
  }

}