import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class InteractiveBarChart extends StatefulWidget {
  final List<double> dailyValues; // 7 days of data
  final Color barColor;
  final Color touchedColor;
  final List<String> dayLabels;

  const InteractiveBarChart({
    super.key,
    required this.dailyValues,
    required this.barColor,
    required this.touchedColor,
    required this.dayLabels,
  });

  @override
  State<InteractiveBarChart> createState() => _InteractiveBarChartState();
}

class _InteractiveBarChartState extends State<InteractiveBarChart> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    return BarChart(
      BarChartData(
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            // tooltipBgColor: Colors.blueGrey, // Removed in newer versions, use getTooltipItem
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
               return BarTooltipItem(
                 '${rod.toY.toStringAsFixed(1)}h',
                 GoogleFonts.poppins(
                   color: Colors.white,
                   fontWeight: FontWeight.bold,
                 ),
               );
            },
          ),
          touchCallback: (FlTouchEvent event, barTouchResponse) {
            setState(() {
              if (!event.isInterestedForInteractions ||
                  barTouchResponse == null ||
                  barTouchResponse.spot == null) {
                _touchedIndex = -1;
                return;
              }
              _touchedIndex = barTouchResponse.spot!.touchedBarGroupIndex;
            });
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (double value, TitleMeta meta) {
                if (value.toInt() >= 0 && value.toInt() < widget.dayLabels.length) {
                   return Padding(
                     padding: const EdgeInsets.only(top: 8.0),
                     child: Text(
                       widget.dayLabels[value.toInt()],
                       style: GoogleFonts.poppins(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold),
                     ),
                   );
                }
                return const SizedBox.shrink();
              },
              reservedSize: 30,
            ),
          ),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        barGroups: widget.dailyValues.asMap().entries.map((entry) {
          final index = entry.key;
          final value = entry.value;
          final isTouched = index == _touchedIndex;
          final isToday = index == widget.dailyValues.length - 1;
          
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: value,
                color: (isTouched || isToday) ? widget.touchedColor : widget.barColor,
                width: 16,
                borderRadius: BorderRadius.circular(4),
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: (widget.dailyValues.reduce((curr, next) => curr > next ? curr : next) * 1.2).clamp(12.0, 24.0), 
                  color: widget.barColor.withOpacity(0.1),
                ),
              ),
            ],
            showingTooltipIndicators: (isTouched || (isToday && _touchedIndex == -1)) ? [0] : [],
          );
        }).toList(),
        gridData: FlGridData(show: false),
        alignment: BarChartAlignment.spaceAround,
        maxY: (widget.dailyValues.reduce((curr, next) => curr > next ? curr : next) * 1.2).clamp(12.0, 24.0), // Dynamic max Y
      ),
      swapAnimationDuration: const Duration(milliseconds: 600),
      swapAnimationCurve: Curves.easeOut,
    );
  }
}
