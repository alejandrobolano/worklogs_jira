import 'package:flutter/material.dart';

enum Days { sunday, monday, thuesday, wednesday, thursday, friday, saturday }

class WorkDay {
  int day;
  double hoursWorked;
  bool isWorking;
  String? reminderTime;
  bool reminderEnabled;

  WorkDay({
    required this.day,
    required this.hoursWorked,
    required this.isWorking,
    this.reminderTime,
    this.reminderEnabled = true,
  });

  TimeOfDay? get reminderTimeOfDay {
    if (reminderTime == null) return null;
    final parts = reminderTime!.split(':');
    if (parts.length != 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return TimeOfDay(hour: h, minute: m);
  }

  set reminderTimeOfDay(TimeOfDay? t) {
    reminderTime = t == null
        ? null
        : '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

  Map<String, dynamic> toMap() {
    return {
      'day': day,
      'hoursWorked': hoursWorked,
      'isWorking': isWorking,
      if (reminderTime != null) 'reminderTime': reminderTime,
      if (!reminderEnabled) 'reminderEnabled': false,
    };
  }

  factory WorkDay.fromMap(Map<String, dynamic> map) {
    return WorkDay(
      day: map['day'],
      hoursWorked: map['hoursWorked'],
      isWorking: map['isWorking'],
      reminderTime: map['reminderTime'] as String?,
      reminderEnabled: map['reminderEnabled'] as bool? ?? true,
    );
  }
}
