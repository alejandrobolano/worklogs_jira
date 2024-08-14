import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:worklogs_jira/src/helper/widget_helper.dart';
import 'package:worklogs_jira/src/models/worklist_response.dart';

class WorkListView extends StatelessWidget {
  final WorklistResponse worklogResponse;
  final Function(String?) launchUrl;

  const WorkListView(
      {super.key, required this.worklogResponse, required this.launchUrl});

  @override
  Widget build(BuildContext context) {
    if (worklogResponse.issues != null && worklogResponse.issues!.isEmpty) {
      return ListTile(
        leading: const Icon(Icons.access_alarms),
        title: Text(AppLocalizations.of(context)!.listEmpty),
      );
    }
    return ListView.builder(
      restorationId: 'WorkListView',
      itemCount:
          worklogResponse.issues != null ? worklogResponse.issues?.length : 0,
      itemBuilder: (BuildContext context, int index) {
        final worklog = worklogResponse.issues?[index];
        final issueKey = worklog?.key;
        final fields = worklog?.fields;
        final double timespent = (worklog?.fields!.timespent ?? 0) / 3600.0;
        final projectName = fields?.project?.name;
        final issueTypeName = fields?.issueType?.name;

        return Card(
            child: ListTile(
          onTap: () =>
              _settingModalBottomSheet(context, launchUrl, issueKey, fields!),
          title: Text('$issueKey'),
          leading: Text('$issueTypeName'),
          subtitle: Text('$projectName | $timespent h'),
          trailing: IconButton(
            icon: const Icon(
              Icons.exit_to_app,
            ),
            onPressed: () => launchUrl(worklog?.key),
          ),
        ));
      },
    );
  }

  void _settingModalBottomSheet(
      context, Function f, String? key, Fields fields) {
    final subtasks = fields.subtasks;
    final status = fields.status?.name;
    final assigneeName = fields.assignee?.displayName;
    final color = WidgetHelper.getRandomColor();
    final subtasksText = _concat(subtasks);
    showModalBottomSheet(
        context: context,
        builder: (BuildContext bc) {
          return Wrap(
            children: <Widget>[
              ListTile(
                  leading: const Icon(Icons.person_outline),
                  iconColor: color,
                  title: Text(
                      '${AppLocalizations.of(context)!.assginee}: $assigneeName')),
              ListTile(
                  onTap: () => launchUrl(key),
                  leading: const Icon(Icons.key),
                  iconColor: color,
                  title:
                      Text('$key | $status', style: TextStyle(color: color))),
              ListTile(
                  leading: const Icon(Icons.comment_bank_outlined),
                  iconColor: color,
                  title: Text('${fields.summary}')),
              if (subtasks!.isNotEmpty)
                ListTile(
                    leading: const Icon(Icons.pending_actions_outlined),
                    iconColor: color,
                    title: Text(
                        '${AppLocalizations.of(context)!.subtasks}: $subtasksText')),
            ],
          );
        });
  }
}

String _concat(List<Issues?>? subtasks) {
  return subtasks!.map((e) => e!.key).join(" | ");
}
