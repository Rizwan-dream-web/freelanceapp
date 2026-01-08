import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

class CurrencyService {
  static const double usdToInr = 83.0; // Current market rate approximation

  static String get globalCurrency {
    final box = Hive.box('settings');
    return box.get('globalCurrency', defaultValue: 'USD');
  }

  static double convert(double amount, String from) {
    final target = globalCurrency;
    if (from == target) return amount;

    if (from == 'USD' && target == 'INR') {
      return amount * usdToInr;
    } else if (from == 'INR' && target == 'USD') {
      return amount / usdToInr;
    }
    return amount;
  }

  static String format(double amount, String from) {
    final target = globalCurrency;
    final convertedAmount = convert(amount, from);
    final symbol = target == 'INR' ? '₹' : '\$';
    
    // Use NumberFormat for pretty printing
    final formatter = NumberFormat.currency(
      symbol: symbol,
      decimalDigits: convertedAmount == convertedAmount.roundToDouble() ? 0 : 2,
    );
    
    return formatter.format(convertedAmount);
  }

  static String get symbol => globalCurrency == 'INR' ? '₹' : '\$';
}
