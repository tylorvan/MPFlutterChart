import 'package:flutter/painting.dart';
import 'package:mp_flutter_chart/chart/mp/core/axis/x_axis.dart';
import 'package:mp_flutter_chart/chart/mp/core/enums/limite_label_postion.dart';
import 'package:mp_flutter_chart/chart/mp/core/enums/x_axis_position.dart';
import 'package:mp_flutter_chart/chart/mp/core/limit_line.dart';
import 'package:mp_flutter_chart/chart/mp/core/render/axis_renderer.dart';
import 'package:mp_flutter_chart/chart/mp/core/transformer/transformer.dart';
import 'package:mp_flutter_chart/chart/mp/core/utils/color_utils.dart';
import 'package:mp_flutter_chart/chart/mp/core/utils/painter_utils.dart';
import 'package:mp_flutter_chart/chart/mp/core/view_port.dart';
import 'package:mp_flutter_chart/chart/mp/core/poolable/point.dart';
import 'package:mp_flutter_chart/chart/mp/core/poolable/size.dart';
import 'package:mp_flutter_chart/chart/mp/core/utils/utils.dart';

class XAxisRenderer extends AxisRenderer {
  XAxis _xAxis;

  XAxisRenderer(ViewPortHandler viewPortHandler, XAxis xAxis, Transformer trans)
      : super(viewPortHandler, trans, xAxis) {
    this._xAxis = xAxis;

    axisLabelPaint = PainterUtils.create(
        null, null, ColorUtils.BLACK, Utils.convertDpToPixel(10));
  }

  void setupGridPaint() {
    gridPaint = Paint()
      ..color = _xAxis.gridColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = _xAxis.gridLineWidth;
  }

  XAxis get xAxis => _xAxis;

  @override
  void computeAxis(double min, double max, bool inverted) {
    // calculate the starting and entry point of the y-labels (depending on
    // zoom / contentrect bounds)
    if (viewPortHandler.contentWidth() > 10 &&
        !viewPortHandler.isFullyZoomedOutX()) {
      MPPointD p1 = trans.getValuesByTouchPoint1(
          viewPortHandler.contentLeft(), viewPortHandler.contentTop());
      MPPointD p2 = trans.getValuesByTouchPoint1(
          viewPortHandler.contentRight(), viewPortHandler.contentTop());

      if (inverted) {
        min = p2.x;
        max = p1.x;
      } else {
        min = p1.x;
        max = p2.x;
      }

      MPPointD.recycleInstance2(p1);
      MPPointD.recycleInstance2(p2);
    }

    computeAxisValues(min, max);
  }

  @override
  void computeAxisValues(double min, double max) {
    super.computeAxisValues(min, max);
    computeSize();
  }

  void computeSize() {
    String longest = _xAxis.getLongestLabel();

    axisLabelPaint = PainterUtils.create(axisLabelPaint, null,
        axisLabelPaint.text.style.color, _xAxis.textSize);

    final FSize labelSize = Utils.calcTextSize1(axisLabelPaint, longest);

    final double labelWidth = labelSize.width;
    final double labelHeight =
        Utils.calcTextHeight(axisLabelPaint, "Q").toDouble();

    final FSize labelRotatedSize = Utils.getSizeOfRotatedRectangleByDegrees(
        labelWidth, labelHeight, _xAxis.labelRotationAngle);

    _xAxis.labelWidth = labelWidth.round();
    _xAxis.labelHeight = labelHeight.round();
    _xAxis.labelRotatedWidth = labelRotatedSize.width.round();
    _xAxis.labelRotatedHeight = labelRotatedSize.height.round();

    FSize.recycleInstance(labelRotatedSize);
    FSize.recycleInstance(labelSize);
  }

  @override
  void renderAxisLabels(Canvas c) {
    if (!_xAxis.enabled || !_xAxis.drawLabels) return;

    axisLabelPaint.text = TextSpan(
        style: TextStyle(fontSize: _xAxis.textSize, color: _xAxis.textColor));

    MPPointF pointF = MPPointF.getInstance1(0, 0);
    if (_xAxis.position == XAxisPosition.TOP) {
      pointF.x = 0.5;
      pointF.y = 1.0;
      drawLabels(c, viewPortHandler.contentTop(), pointF, _xAxis.position);
    } else if (_xAxis.position == XAxisPosition.TOP_INSIDE) {
      pointF.x = 0.5;
      pointF.y = 1.0;
      drawLabels(c, viewPortHandler.contentTop() + _xAxis.labelRotatedHeight,
          pointF, _xAxis.position);
    } else if (_xAxis.position == XAxisPosition.BOTTOM) {
      pointF.x = 0.5;
      pointF.y = 0.0;
      drawLabels(c, viewPortHandler.contentBottom(), pointF, _xAxis.position);
    } else if (_xAxis.position == XAxisPosition.BOTTOM_INSIDE) {
      pointF.x = 0.5;
      pointF.y = 0.0;
      drawLabels(
          c,
          viewPortHandler.contentBottom() - _xAxis.labelRotatedHeight,
          pointF,
          _xAxis.position);
    } else {
      // BOTH SIDED
      pointF.x = 0.5;
      pointF.y = 1.0;
      drawLabels(c, viewPortHandler.contentTop(), pointF, XAxisPosition.TOP);
      pointF.x = 0.5;
      pointF.y = 0.0;
      drawLabels(
          c, viewPortHandler.contentBottom(), pointF, XAxisPosition.BOTTOM);
    }
    MPPointF.recycleInstance(pointF);
  }

  @override
  void renderAxisLine(Canvas c) {
    if (!_xAxis.drawAxisLine || !_xAxis.enabled) return;

    axisLinePaint = Paint()
      ..color = _xAxis.axisLineColor
      ..strokeWidth = _xAxis.axisLineWidth;

    if (_xAxis.position == XAxisPosition.TOP ||
        _xAxis.position == XAxisPosition.TOP_INSIDE ||
        _xAxis.position == XAxisPosition.BOTH_SIDED) {
      c.drawLine(
          Offset(viewPortHandler.contentLeft(), viewPortHandler.contentTop()),
          Offset(
              viewPortHandler.contentRight(), viewPortHandler.contentTop()),
          axisLinePaint);
    }

    if (_xAxis.position == XAxisPosition.BOTTOM ||
        _xAxis.position == XAxisPosition.BOTTOM_INSIDE ||
        _xAxis.position == XAxisPosition.BOTH_SIDED) {
      c.drawLine(
          Offset(
              viewPortHandler.contentLeft(), viewPortHandler.contentBottom()),
          Offset(viewPortHandler.contentRight(),
              viewPortHandler.contentBottom()),
          axisLinePaint);
    }
  }

  /// draws the x-labels on the specified y-position
  ///
  /// @param pos
  void drawLabels(
      Canvas c, double pos, MPPointF anchor, XAxisPosition position) {
    final double labelRotationAngleDegrees = _xAxis.labelRotationAngle;
    bool centeringEnabled = _xAxis.isCenterAxisLabelsEnabled();

    List<double> positions = List(_xAxis.entryCount * 2);

    for (int i = 0; i < positions.length; i += 2) {
      // only fill x values
      if (centeringEnabled) {
        positions[i] = _xAxis.centeredEntries[i ~/ 2];
      } else {
        positions[i] = _xAxis.entries[i ~/ 2];
      }
      positions[i + 1] = 0;
    }

    trans.pointValuesToPixel(positions);

    for (int i = 0; i < positions.length; i += 2) {
      double x = positions[i];

      if (viewPortHandler.isInBoundsX(x)) {
        String label = _xAxis
            .getValueFormatter()
            .getAxisLabel(_xAxis.entries[i ~/ 2], _xAxis);

        if (_xAxis.avoidFirstLastClipping) {
          // avoid clipping of the last
          if (i / 2 == _xAxis.entryCount - 1 && _xAxis.entryCount > 1) {
            double width =
                Utils.calcTextWidth(axisLabelPaint, label).toDouble();

            if (width > viewPortHandler.offsetRight() * 2 &&
                x + width > viewPortHandler.getChartWidth()) x -= width / 2;

            // avoid clipping of the first
          } else if (i == 0) {
            double width =
                Utils.calcTextWidth(axisLabelPaint, label).toDouble();
            x += width / 2;
          }
        }

        drawLabel(
            c, label, x, pos, anchor, labelRotationAngleDegrees, position);
      }
    }
  }

  void drawLabel(Canvas c, String formattedLabel, double x, double y,
      MPPointF anchor, double angleDegrees, XAxisPosition position) {
    Utils.drawXAxisValue(c, formattedLabel, x, y, axisLabelPaint, anchor,
        angleDegrees, position);
  }

  Path mRenderGridLinesPath = Path();
  List<double> mRenderGridLinesBuffer = List(2);

  @override
  void renderGridLines(Canvas c) {
    if (!_xAxis.drawGridLines || !_xAxis.enabled) return;

    c.save();
    c.clipRect(getGridClippingRect());

    if (mRenderGridLinesBuffer.length != axis.entryCount * 2) {
      mRenderGridLinesBuffer = List(_xAxis.entryCount * 2);
    }
    List<double> positions = mRenderGridLinesBuffer;

    for (int i = 0; i < positions.length; i += 2) {
      positions[i] = _xAxis.entries[i ~/ 2];
      positions[i + 1] = _xAxis.entries[i ~/ 2];
    }
    trans.pointValuesToPixel(positions);

    setupGridPaint();

    Path gridLinePath = mRenderGridLinesPath;
    gridLinePath.reset();

    for (int i = 0; i < positions.length; i += 2) {
      drawGridLine(c, positions[i], positions[i + 1], gridLinePath);
    }

    c.restore();
  }

  Rect mGridClippingRect = Rect.zero;

  Rect getGridClippingRect() {
    mGridClippingRect = Rect.fromLTRB(
        viewPortHandler.getContentRect().left - axis.gridLineWidth,
        viewPortHandler.getContentRect().top - axis.gridLineWidth,
        viewPortHandler.getContentRect().right,
        viewPortHandler.getContentRect().bottom);
    return mGridClippingRect;
  }

  /// Draws the grid line at the specified position using the provided path.
  ///
  /// @param c
  /// @param x
  /// @param y
  /// @param gridLinePath
  void drawGridLine(Canvas c, double x, double y, Path path) {
    path.moveTo(x, viewPortHandler.contentBottom());
    path.lineTo(x, viewPortHandler.contentTop());

    // draw a path because lines don't support dashing on lower android versions
    c.drawPath(path, gridPaint);

    path.reset();
  }

  List<double> mRenderLimitLinesBuffer = List(2);
  Rect mLimitLineClippingRect = Rect.zero;

  /// Draws the LimitLines associated with this axis to the screen.
  ///
  /// @param c
  @override
  void renderLimitLines(Canvas c) {
    List<LimitLine> limitLines = _xAxis.getLimitLines();

    if (limitLines == null || limitLines.length <= 0) return;

    List<double> position = mRenderLimitLinesBuffer;
    position[0] = 0;
    position[1] = 0;

    for (int i = 0; i < limitLines.length; i++) {
      LimitLine l = limitLines[i];

      if (!l.enabled) continue;

      c.save();
      mLimitLineClippingRect = Rect.fromLTRB(
          viewPortHandler.getContentRect().left - l.lineWidth,
          viewPortHandler.getContentRect().top - l.lineWidth,
          viewPortHandler.getContentRect().right,
          viewPortHandler.getContentRect().bottom);
      c.clipRect(mLimitLineClippingRect);

      position[0] = l.limit;
      position[1] = 0;

      trans.pointValuesToPixel(position);

      renderLimitLineLine(c, l, position);
      renderLimitLineLabel(c, l, position, 2.0 + l.yOffset);

      c.restore();
    }
  }

  List<double> mLimitLineSegmentsBuffer = List(4);
  Path mLimitLinePath = Path();

  void renderLimitLineLine(
      Canvas c, LimitLine limitLine, List<double> position) {
    mLimitLineSegmentsBuffer[0] = position[0];
    mLimitLineSegmentsBuffer[1] = viewPortHandler.contentTop();
    mLimitLineSegmentsBuffer[2] = position[0];
    mLimitLineSegmentsBuffer[3] = viewPortHandler.contentBottom();

    mLimitLinePath.reset();
    mLimitLinePath.moveTo(
        mLimitLineSegmentsBuffer[0], mLimitLineSegmentsBuffer[1]);
    mLimitLinePath.lineTo(
        mLimitLineSegmentsBuffer[2], mLimitLineSegmentsBuffer[3]);

    limitLinePaint
      ..style = PaintingStyle.stroke
      ..color = limitLine.lineColor
      ..strokeWidth = limitLine.lineWidth;

    c.drawPath(mLimitLinePath, limitLinePaint);
  }

  void renderLimitLineLabel(
      Canvas c, LimitLine limitLine, List<double> position, double yOffset) {
    String label = limitLine.label;

    // if drawing the limit-value label is enabled
    if (label != null && label.isNotEmpty) {
      var painter = PainterUtils.create(
          null, label, limitLine.textColor, limitLine.textSize);

      double xOffset = limitLine.lineWidth + limitLine.xOffset;

      final LimitLabelPosition labelPosition = limitLine.labelPosition;

      if (labelPosition == LimitLabelPosition.RIGHT_TOP) {
        final double labelLineHeight =
            Utils.calcTextHeight(painter, label).toDouble();
        painter.textAlign = TextAlign.left;
        painter.layout();
        painter.paint(
            c,
            Offset(position[0] + xOffset,
                viewPortHandler.contentTop() + yOffset + labelLineHeight));
      } else if (labelPosition == LimitLabelPosition.RIGHT_BOTTOM) {
        painter.textAlign = TextAlign.left;
        painter.layout();
        painter.paint(
            c,
            Offset(position[0] + xOffset,
                viewPortHandler.contentBottom() - yOffset));
      } else if (labelPosition == LimitLabelPosition.LEFT_TOP) {
        painter.textAlign = TextAlign.right;
        final double labelLineHeight =
            Utils.calcTextHeight(painter, label).toDouble();
        painter.layout();
        painter.paint(
            c,
            Offset(position[0] - xOffset,
                viewPortHandler.contentTop() + yOffset + labelLineHeight));
      } else {
        painter.textAlign = TextAlign.right;
        painter.layout();
        painter.paint(
            c,
            Offset(position[0] - xOffset,
                viewPortHandler.contentBottom() - yOffset));
      }
    }
  }
}
