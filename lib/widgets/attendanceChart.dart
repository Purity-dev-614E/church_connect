import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class AttendanceChart extends StatelessWidget {
  final List<String> periods;          // week, month, quarter, year
  final String selectedPeriod;
  final List<String> labels;           // x-axis
  final List<double> values;           // y-axis
  final ValueChanged<String?>? onPeriodChange;

  final bool isLoading;

  const AttendanceChart({
    super.key,
    required this.periods,
    required this.selectedPeriod,
    required this.labels,
    required this.values,
    required this.onPeriodChange,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final labelStride =
        labels.length <= 8 ? 1 : (labels.length / 6).ceil();
    final maxValue = values.isEmpty ? 0.0 : values.reduce(math.max);
    final tentativeMax = (maxValue / 10).ceil() * 10 + 5;
    final maxY = math.max(10.0, math.min(100.0, tentativeMax.toDouble()));
    final horizontalInterval = math.max(2.0, maxY / 5);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Text("Attendance Overview", style: Theme.of(context).textTheme.titleMedium),
        DropdownButton<String>(
          value: selectedPeriod,
          items: periods
              .map((p) => DropdownMenuItem(value: p, child: Text(p.toUpperCase())))
              .toList(),
          onChanged: onPeriodChange,
        ),
        SizedBox(
          height: 220,
          child: values.isEmpty
              ? const Center(child: Text('No attendance data available'))
              : LineChart(
                  LineChartData(
                    minX: 0,
                    maxX: (values.length - 1).toDouble(),
                    minY: 0,
                    maxY: maxY.toDouble(),
                    clipData: const FlClipData.all(),
                    lineBarsData: [
                      LineChartBarData(
                        isCurved: false,
                        barWidth: 3,
                        color: Theme.of(context).colorScheme.primary,
                        spots: values.asMap().entries
                            .map((e) => FlSpot(e.key.toDouble(), e.value))
                            .toList(),
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.1),
                        ),
                      )
                    ],
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: horizontalInterval,
                    ),
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 48,
                          getTitlesWidget: (value, _) {
                            final index = value.round();
                            if (index < 0 ||
                                index >= labels.length ||
                                index % labelStride != 0) {
                              return const SizedBox.shrink();
                            }
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Transform.rotate(
                                angle: -math.pi / 6,
                                child: SizedBox(
                                  width: 60,
                                  child: Text(
                                    labels[index],
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      leftTitles: const AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 36,
                        ),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    borderData: FlBorderData(
                      show: true,
                      border: Border.all(
                        color: Theme.of(context)
                            .colorScheme
                            .outline
                            .withOpacity(0.3),
                      ),
                    ),
                  ),
                ),
        )
      ],
    );
  }
}
