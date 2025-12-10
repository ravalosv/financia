import 'dart:math';
import 'package:intl/intl.dart';

class Helpers {
  static String generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString() + 
           Random().nextInt(9999).toString().padLeft(4, '0');
  }

  static String formatCurrency(double amount, String currency) {
    final formatter = NumberFormat.currency(
      symbol: _getCurrencySymbol(currency),
      decimalDigits: 2,
    );
    return formatter.format(amount);
  }

  static String _getCurrencySymbol(String currency) {
    switch (currency.toUpperCase()) {
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      case 'JPY':
        return '¥';
      case 'MXN':
        return '\$';
      default:
        return '\$';
    }
  }

  static String formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }

  static String formatMonthYear(DateTime date) {
    return DateFormat('yyyy-MM').format(date);
  }

  static String getMonthYearFromString(String monthYear) {
    final parts = monthYear.split('-');
    if (parts.length != 2) return monthYear;
    
    final year = int.tryParse(parts[0]) ?? 0;
    final month = int.tryParse(parts[1]) ?? 0;
    
    if (year == 0 || month == 0 || month < 1 || month > 12) return monthYear;
    
    final date = DateTime(year, month);
    return DateFormat('MMMM yyyy').format(date);
  }

  static double calculatePercentage(double value, double total) {
    if (total == 0) return 0.0;
    return (value / total * 100).clamp(0.0, 100.0);
  }

  static bool isSameMonthYear(DateTime date1, DateTime date2) {
    return date1.year == date2.year && date1.month == date2.month;
  }

  static DateTime getFirstDayOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  static DateTime getLastDayOfMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0);
  }
}