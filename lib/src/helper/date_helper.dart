import 'package:intl/intl.dart';

class DateHelper {
  static DateTime getInitialDate() {
    var initialDate = DateTime.now();
    if (initialDate.weekday == DateTime.saturday) {
      initialDate = initialDate.add(const Duration(days: 2));
    } else if (initialDate.weekday == DateTime.sunday) {
      initialDate = initialDate.add(const Duration(days: 1));
    }
    return initialDate;
  }

  static String formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  static String getFirstDayOfMonth() {
    var month = DateTime.now().month;
    var year = DateTime.now().year;
    return formatDate(DateTime(year, month, 1));
  }
}
