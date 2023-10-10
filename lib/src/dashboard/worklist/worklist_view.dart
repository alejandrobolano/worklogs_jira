import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:worklogs_jira/src/models/worklist_response.dart';

class WorkListView extends StatelessWidget {
  final WorklistResponse worklogResponse;

  const WorkListView({super.key, required this.worklogResponse});

  @override
  Widget build(BuildContext context) {
    if (worklogResponse.issues != null && worklogResponse.issues!.isEmpty) {
      return ListTile(
        leading: const Icon(Icons.access_alarms),
        title: Text(AppLocalizations.of(context)!.issueEmpty),
      );
    }
    return ListView.builder(
      restorationId: 'WorkListView',
      itemCount:
          worklogResponse.issues != null ? worklogResponse.issues?.length : 0,
      itemBuilder: (BuildContext context, int index) {
        final worklog = worklogResponse.issues?[index];
        final issueKey = worklog?.key;
        final double timespent = (worklog?.fields!.timespent ?? 0) / 3600.0;
        final projectName = worklog?.fields?.project?.name;
        final issueTypeName = worklog?.fields?.issueType?.name;

        return Card(
            child: ListTile(
          onTap: () => _settingModalBottomSheet(context, worklog!),
          title: Text('$issueKey'),
          leading: Text('$issueTypeName'),
          subtitle: Text('$projectName | $timespent h'),
        ));
      },
    );
  }

  void _settingModalBottomSheet(context, Issues issues) {
    final subtasks = issues.fields?.subtasks;
    final assigneeName = issues.fields?.assignee?.displayName;
    showModalBottomSheet(
        context: context,
        builder: (BuildContext bc) {
          return Wrap(
            children: <Widget>[
              ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: Text(
                      '${AppLocalizations.of(context)!.assginee}: $assigneeName')),
              ListTile(
                  leading: const Icon(Icons.key), title: Text('${issues.key}')),
              ListTile(
                  leading: const Icon(Icons.comment_bank_outlined),
                  title: Text('${issues.fields?.summary}')),
              if (subtasks!.isNotEmpty)
                ListTile(
                    leading: const Icon(Icons.pending_actions_outlined),
                    title: Text(_concat(subtasks))),
            ],
          );
        });
  }
}

String _concat(List<Issues?>? subtasks) {
  return subtasks!.map((e) => e!.key).join(" | ");
}
