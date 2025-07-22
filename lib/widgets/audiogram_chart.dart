import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/hearing_test_model.dart';

class AudiogramChart extends StatelessWidget {
  final HearingTestModel test;
  const AudiogramChart({Key? key, required this.test}) : super(key: key);

  static const List<int> frequencies = [250, 500, 1000, 2000, 4000, 8000];

  @override
  Widget build(BuildContext context) {
    // Prepare data, handle missing/null thresholds
    List<FlSpot> leftSpots = [];
    List<FlSpot> rightSpots = [];
    for (int i = 0; i < frequencies.length; i++) {
      final freq = frequencies[i].toString();
      final left = test.leftEarThresholds[freq];
      final right = test.rightEarThresholds[freq];
      if (left != null) {
        leftSpots.add(FlSpot(i.toDouble(), left));
      }
      if (right != null) {
        rightSpots.add(FlSpot(i.toDouble(), right));
      }
    }

    return SizedBox(
      height: 220,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: (frequencies.length - 1).toDouble(),
          minY: 0,
          maxY: 120,
          lineBarsData: [
            LineChartBarData(
              spots: leftSpots,
              isCurved: false,
              color: Colors.red,
              barWidth: 3,
              dotData: FlDotData(show: true),
              belowBarData: BarAreaData(show: false),
            ),
            LineChartBarData(
              spots: rightSpots,
              isCurved: false,
              color: Colors.blue,
              barWidth: 3,
              dotData: FlDotData(show: true),
              belowBarData: BarAreaData(show: false),
            ),
          ],
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 36,
                getTitlesWidget: (value, meta) {
                  // Show every 20 dB
                  if (value % 20 == 0) {
                    return Text('${value.toInt()}');
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  int idx = value.toInt();
                  if (idx >= 0 && idx < frequencies.length) {
                    return Text('${frequencies[idx]}');
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(show: true, horizontalInterval: 20),
          borderData: FlBorderData(show: true),
          // Reverse Y-axis: lower dB at top, higher at bottom
          lineTouchData: LineTouchData(enabled: true),
        ),
      ),
    );
  }
} 