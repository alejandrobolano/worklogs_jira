import 'package:intl/intl.dart';

class DateHelper {
  static DateTime getInitialDate(List<int> notWorkedDays) {
    var initialDate = DateTime.now();
    initialDate = checkInitialDate(notWorkedDays, initialDate);
    return initialDate;
  }

  static DateTime checkInitialDate(
      List<int> notWorkedDays, DateTime initialDate) {
    if (notWorkedDays.isNotEmpty) {
      if (notWorkedDays.contains(initialDate.weekday)) {
        initialDate = initialDate.add(const Duration(days: 1));
        return checkInitialDate(notWorkedDays, initialDate);
      }
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

  static String getDay(int day) {
    switch (day) {
      case 1:
        return "monday";
      case 2:
        return "tuesday";
      case 3:
        return "wednesday";
      case 4:
        return "thursday";
      case 5:
        return "friday";
      case 6:
        return "saturday";
      case 7:
        return "sunday";
      default:
        return "not found";
    }
  }
}
