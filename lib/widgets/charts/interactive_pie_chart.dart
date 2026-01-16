import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class InteractivePieChart extends StatefulWidget {
  final double value; // 0.0 to 1.0 (or higher if overburn)
  final Color baseColor;
  final Color progressColor;
  final String centerText;
  final String centerSubtext;

  const InteractivePieChart({
    super.key,
    required this.value,
    required this.baseColor,
    required this.progressColor,
    required this.centerText,
    this.centerSubtext = '',
  });

  @override
  State<InteractivePieChart> createState() => _InteractivePieChartState();
}

class _InteractivePieChartState extends State<InteractivePieChart> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    // Clamp value for visual sanity, but we could handle > 1.0 differently (e.g. red color)
    final double visualValue = widget.value.clamp(0.0, 1.0);
    final double remaining = 1.0 - visualValue;

    return SizedBox(
      height: 150,
      width: 150,
      child: Stack(
        children: [
          PieChart(
            PieChartData(
              pieTouchData: PieTouchData(
                touchCallback: (FlTouchEvent event, pieTouchResponse) {
                  setState(() {
                    if (!event.isInterestedForInteractions ||
                        pieTouchResponse == null ||
                        pieTouchResponse.touchedSection == null) {
                      _touchedIndex = -1;
                      return;
                    }
                    _touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                  });
                },
              ),
              borderData: FlBorderData(show: false),
              sectionsSpace: 0,
              centerSpaceRadius: 55,
              startDegreeOffset: 270, // Start from top
              sections: [
                PieChartSectionData(
                  color: widget.progressColor,
                  value: visualValue * 100,
                  title: '',
                  radius: _touchedIndex == 0 ? 20 : 15,
                  titleStyle: const TextStyle(fontSize: 0, fontWeight: FontWeight.bold, color: Colors.white),
                  badgeWidget: _touchedIndex == 0
                      ? Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                          ),
                          child: Icon(Icons.bolt, size: 12, color: widget.progressColor),
                        )
                      : null,
                  badgePositionPercentageOffset: 0.98,
                ),
                PieChartSectionData(
                  color: widget.baseColor.withOpacity(0.1),
                  value: remaining * 100,
                  title: '',
                  radius: _touchedIndex == 1 ? 18 : 15,
                ),
              ],
            ),
            swapAnimationDuration: const Duration(milliseconds: 800),
            swapAnimationCurve: Curves.easeOutQuart,
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  widget.centerText,
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                if (widget.centerSubtext.isNotEmpty)
                  Text(
                    widget.centerSubtext,
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
