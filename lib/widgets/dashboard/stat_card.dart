import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/currency_service.dart';
import '../app_card.dart';

class StatCard extends StatelessWidget {
  final String title;
  final double value;
  final IconData icon;
  final Color color;
  final bool isCurrency;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.isCurrency = false,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(12),
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: value),
            duration: const Duration(seconds: 1),
            curve: Curves.easeOutExpo,
            builder: (context, val, _) {
              return FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  isCurrency ? CurrencyService.format(val, CurrencyService.globalCurrency) : val.toInt().toString(),
                  style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              );
            },
          ),
          Text(title, style: GoogleFonts.poppins(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
