class DailyTask {
  final String issue;
  final double hours;

  DailyTask({required this.issue, required this.hours});

  Map<String, dynamic> toMap() => {'issue': issue, 'hours': hours};

  factory DailyTask.fromMap(Map<String, dynamic> map) => DailyTask(
        issue: map['issue'] as String,
        hours: (map['hours'] as num).toDouble(),
      );
}
