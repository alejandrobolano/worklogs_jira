import 'package:flutter/material.dart';
import 'package:worklogs_jira/src/models/worklist_response.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class LoggedTasksTable extends StatefulWidget {
  const LoggedTasksTable({
    super.key,
    required this.issues,
    required this.onTaskTap,
    required this.getWorklogsCallback,
  });

  final List<Issues?>? issues;
  final Function(String?) onTaskTap;
  final Future<Map<String, dynamic>> Function(String) getWorklogsCallback;

  @override
  State<LoggedTasksTable> createState() => _LoggedTasksTableState();
}

class _LoggedTasksTableState extends State<LoggedTasksTable> {
  Map<String, List<Map<String, dynamic>>> _tasksByDate = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWorklogs();
  }

  @override
  void didUpdateWidget(LoggedTasksTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.issues != oldWidget.issues) {
      _loadWorklogs();
    }
  }

  Future<void> _loadWorklogs() async {
    if (widget.issues == null || widget.issues!.isEmpty) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _tasksByDate = {};
    });

    for (var issue in widget.issues!) {
      if (issue == null) continue;
      try {
        final worklogsData = await widget.getWorklogsCallback(issue.key ?? '');
        final worklogs = worklogsData['worklogs'] as List<dynamic>?;

        if (worklogs != null) {
          for (var worklog in worklogs) {
            final started = worklog['started'] as String?;
            final timeSpentSeconds = worklog['timeSpentSeconds'] as int?;

            if (started != null && timeSpentSeconds != null) {
              final dateTime = DateTime.parse(started);
              final dateKey = DateFormat('yyyy-MM-dd').format(dateTime);

              if (!_tasksByDate.containsKey(dateKey)) {
                _tasksByDate[dateKey] = [];
              }

              _tasksByDate[dateKey]!.add({
                'key': issue.key,
                'summary': issue.fields?.summary,
                'hours': timeSpentSeconds / 3600.0,
                'status': issue.fields?.status?.name,
              });
            }
          }
        }
      } catch (e) {
        debugPrint('Error loading worklogs for ${issue.key}: $e');
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_tasksByDate.isEmpty) {
      return Center(
        child: Text(AppLocalizations.of(context)?.listEmpty ?? ''),
      );
    }

    final sortedDates = _tasksByDate.keys.toList()..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Text(
            AppLocalizations.of(context)?.loggedTasks ?? 'Logged Tasks',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: sortedDates.map((dateKey) {
                  final date = DateTime.parse(dateKey);
                  final tasks = _tasksByDate[dateKey]!;
                  final totalHours = tasks.fold<double>(
                    0.0,
                    (sum, task) => sum + (task['hours'] as double),
                  );

                  return Container(
                    width: 250,
                    margin: const EdgeInsets.only(right: 8.0),
                    child: Card(
                      elevation: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12.0),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(0.1),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(4),
                                topRight: Radius.circular(4),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  DateFormat('EEEE', 'es').format(date),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  DateFormat('dd/MM/yyyy').format(date),
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${totalHours.toStringAsFixed(2)}h',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ...tasks.map((task) {
                            return InkWell(
                              onTap: () =>
                                  widget.onTaskTap(task['key'] as String?),
                              child: Container(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      task['key'] as String,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      (task['summary'] as String).length > 40
                                          ? '${(task['summary'] as String).substring(0, 40)}...'
                                          : task['summary'] as String,
                                      style:
                                          Theme.of(context).textTheme.bodySmall,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '${(task['hours'] as double).toStringAsFixed(2)}h',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        if (task['status'] != null)
                                          Chip(
                                            label: Text(
                                              task['status'] as String,
                                              style:
                                                  const TextStyle(fontSize: 10),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 6, vertical: 0),
                                            visualDensity:
                                                VisualDensity.compact,
                                            materialTapTargetSize:
                                                MaterialTapTargetSize
                                                    .shrinkWrap,
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
