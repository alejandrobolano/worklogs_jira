enum Days { sunday, monday, thuesday, wednesday, thursday, friday, saturday }

class WorkDay {
  int day;
  double hoursWorked;
  bool isWorking;

  WorkDay(
      {required this.day, required this.hoursWorked, required this.isWorking});

  Map<String, dynamic> toMap() {
    return {'day': day, 'hoursWorked': hoursWorked, 'isWorking': isWorking};
  }

  factory WorkDay.fromMap(Map<String, dynamic> map) {
    return WorkDay(
      day: map['day'],
      hoursWorked: map['hoursWorked'],
      isWorking: map['isWorking'],
    );
  }
}
