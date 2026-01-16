import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_card.dart';
import '../charts/interactive_pie_chart.dart';
import '../animations.dart';

class TimeBurnCard extends StatelessWidget {
  final double tracked;
  final double estimated;
  final double burnRate;

  const TimeBurnCard({
    super.key,
    required this.tracked,
    required this.estimated,
    required this.burnRate,
  });

  @override
  Widget build(BuildContext context) {
    // Determine status and color
    final isOverburn = tracked > estimated;
    final Color mainColor = isOverburn ? Colors.redAccent : (burnRate > 0.8 ? Colors.orangeAccent : Colors.tealAccent);
    final String statusText = isOverburn ? "OVERBURN!" : (burnRate > 0.8 ? "Burning Fast" : "Healthy Burn");

    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 2,
                child: InteractivePieChart(
                  value: burnRate.clamp(0.0, 1.0),
                  baseColor: mainColor,
                  progressColor: mainColor,
                  centerText: '${(burnRate * 100).toInt()}%',
                  centerSubtext: 'BURNED',
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatLine('Budget', '${estimated.toInt()}h', Colors.grey),
                    const SizedBox(height: 12),
                    _buildStatLine('Used', '${tracked.toStringAsFixed(1)}h', mainColor),
                    if (isOverburn) ...[
                       const SizedBox(height: 12),
                       Text('Exceeded by ${(tracked - estimated).toStringAsFixed(1)}h', 
                        style: GoogleFonts.poppins(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold)
                       ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            width: double.infinity,
            decoration: BoxDecoration(
              color: mainColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              statusText.toUpperCase(),
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: mainColor,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatLine(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.poppins(color: Colors.grey, fontSize: 13)),
        Text(value, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15, color: color == Colors.grey ? null : color)),
      ],
    );
  }
}
