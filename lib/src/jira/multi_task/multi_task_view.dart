import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:worklogs_jira/src/helper/date_helper.dart';
import 'package:worklogs_jira/src/helper/widget_helper.dart';
import 'package:worklogs_jira/src/localization/app_localizations.dart';
import 'package:worklogs_jira/src/models/daily_task.dart';
import '../jira_controller.dart';

class MultiTaskView extends StatefulWidget {
  const MultiTaskView({super.key, required this.controller});

  static const routeName = '/multi-task';
  final JiraController controller;

  @override
  State<MultiTaskView> createState() => _MultiTaskViewState();
}

class _MultiTaskViewState extends State<MultiTaskView> {
  List<DailyTask> _tasks = [];
  late String _date = DateHelper.formatDate(DateTime.now());
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadDraft();
  }

  Future<void> _loadDraft() async {
    final tasks = await widget.controller.getDraftTasks();
    final date = await widget.controller.getDraftDate();
    if (mounted) {
      setState(() {
        _tasks = tasks;
        if (date != null && date.isNotEmpty) {
          _date = date;
        }
      });
    }
  }

  void _saveDraft() {
    widget.controller.saveDraftTasks(_tasks, _date);
  }

  void _showAddTaskDialog() async {
    final prefix = await widget.controller.getIssuePreffix() ?? '';
    final issueCtrl = TextEditingController(text: prefix);
    final hoursCtrl = TextEditingController();
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.addTask),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: issueCtrl,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: AppLocalizations.of(context)?.issue,
              ),
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: hoursCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: AppLocalizations.of(context)?.hours,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final issue = issueCtrl.text.trim().toUpperCase();
              final hoursStr = hoursCtrl.text.replaceAll(',', '.');
              final hours = double.tryParse(hoursStr);
              if (issue.isEmpty || hours == null || hours <= 0) return;
              Navigator.of(ctx).pop();
              setState(() {
                _tasks = List.from(_tasks)
                  ..add(DailyTask(issue: issue, hours: hours));
              });
              _saveDraft();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _deleteTask(int index) {
    setState(() {
      _tasks = List.from(_tasks)..removeAt(index);
    });
    _saveDraft();
  }

  Future<void> _showDatePicker() async {
    final List<int> notWorkedDays =
        await widget.controller.getNotWorkedDays();
    if (!mounted) return;
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(_date) ?? DateTime.now(),
      firstDate: DateTime(DateTime.now().year - 3),
      lastDate: DateTime(2101),
      selectableDayPredicate: (DateTime val) =>
          !notWorkedDays.contains(val.weekday),
    );
    if (pickedDate != null) {
      setState(() {
        _date = DateHelper.formatDate(pickedDate);
      });
      _saveDraft();
    }
  }

  Future<void> _logAll() async {
    if (_tasks.isEmpty) {
      WidgetHelper.showMessageSnackBar(
          context, AppLocalizations.of(context)!.noTasksToLog);
      return;
    }

    final date = DateTime.tryParse(_date) ?? DateTime.now();
    final maxHours = await widget.controller.getHoursForDay(date);
    final total = _tasks.fold(0.0, (sum, t) => sum + t.hours);

    if (total > maxHours) {
      if (!mounted) return;
      final continueAnyway = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          content: Text(
            AppLocalizations.of(context)!.hoursExceeded(
              total.toStringAsFixed(1),
              maxHours.toStringAsFixed(1),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(AppLocalizations.of(context)!.reviewTasks),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(AppLocalizations.of(context)!.continueAnyway),
            ),
          ],
        ),
      );
      if (continueAnyway != true) return;
    }

    await _submitAll();
  }

  Future<void> _submitAll() async {
    setState(() => _isLoading = true);
    final response =
        await widget.controller.postMultipleTasksForDay(_date, _tasks);

    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final nav = Navigator.of(context);

    if (widget.controller.isOkStatusCode(response.statusCode)) {
      await widget.controller.clearDraftTasks();
      widget.controller.setLastLoggedDate(_date);
      if (!mounted) return;
      WidgetHelper.showMessageSnackBar(context, l10n.allTasksLogged);
      nav.pop(true);
    } else {
      WidgetHelper.showMessageSnackBar(
          context,
          '${l10n.errorRequest} | ${response.reasonPhrase}');
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final double total = _tasks.fold(0.0, (sum, t) => sum + t.hours);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.multiTaskTitle),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              readOnly: true,
              controller: TextEditingController(text: _date),
              onTap: _showDatePicker,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                suffixIcon: const Icon(Icons.calendar_today),
                labelText: AppLocalizations.of(context)?.startDate,
              ),
            ),
            const SizedBox(height: 12),
            FutureBuilder<double>(
              future: widget.controller.getHoursForDay(
                  DateTime.tryParse(_date) ?? DateTime.now()),
              builder: (context, snapshot) {
                final max = snapshot.data ?? 8.0;
                return Text(
                  AppLocalizations.of(context)!.totalHoursInfo(
                    total.toStringAsFixed(1),
                    max.toStringAsFixed(1),
                  ),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: total > max ? Colors.red : null,
                      ),
                );
              },
            ),
            const SizedBox(height: 12),
            if (_isLoading) const LinearProgressIndicator(),
            const SizedBox(height: 8),
            Expanded(
              child: _tasks.isEmpty
                  ? Center(
                      child: Text(
                        AppLocalizations.of(context)!.noTasksToLog,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    )
                  : ListView.builder(
                      itemCount: _tasks.length,
                      itemBuilder: (context, index) {
                        final task = _tasks[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            title: Text(task.issue),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${task.hours}h',
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: () => _deleteTask(index),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const BottomAppBar(
        shape: CircularNotchedRectangle(),
        height: 65,
      ),
      floatingActionButton: Container(
        margin: const EdgeInsets.all(10),
        child: SpeedDial(
          heroTag: 'multi-task-dial',
          useRotationAnimation: true,
          direction: SpeedDialDirection.up,
          icon: Icons.expand_less,
          activeIcon: Icons.expand_more,
          closeManually: false,
          curve: Curves.bounceIn,
          children: [
            SpeedDialChild(
              child: const Icon(Icons.send),
              label: AppLocalizations.of(context)!.logAll,
              onTap: _isLoading ? null : _logAll,
            ),
            SpeedDialChild(
              child: const Icon(Icons.add),
              label: AppLocalizations.of(context)!.addTask,
              onTap: _showAddTaskDialog,
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.miniEndDocked,
      floatingActionButtonAnimator: FloatingActionButtonAnimator.scaling,
    );
  }
}
