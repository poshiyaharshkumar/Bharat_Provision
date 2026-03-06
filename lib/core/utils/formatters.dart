import 'package:intl/intl.dart';

class Formatters {
  static final NumberFormat _indianCurrencyFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  static final DateFormat dateFormat = DateFormat('dd/MM/yyyy');
  static final DateFormat timeFormat = DateFormat('hh:mm a');

  static String formatCurrency(num value) {
    return _indianCurrencyFormat.format(value);
  }

  static String formatDate(DateTime dateTime) {
    return dateFormat.format(dateTime);
  }

  static String formatTime(DateTime dateTime) {
    return timeFormat.format(dateTime);
  }
}

