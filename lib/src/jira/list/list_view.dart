import 'package:flutter/material.dart';
import '../models/jira_response.dart';

class JiraListView extends StatelessWidget {
  final JiraResponse jiraResponse;
  final Function(Worklog) onDeleteData;

  const JiraListView(
      {super.key, required this.jiraResponse, required this.onDeleteData});

  @override
  Widget build(BuildContext context) {
    if (jiraResponse.worklogs != null && jiraResponse.worklogs?.length == 0) {
      return const ListTile(
        leading: Icon(Icons.access_alarms),
        title: Text("This issue has not worklogs"),
      );
    }
    return ListView.builder(
      restorationId: 'JiraListView',
      itemCount:
          jiraResponse.worklogs != null ? jiraResponse.worklogs?.length : 0,
      itemBuilder: (BuildContext context, int index) {
        final worklog = jiraResponse.worklogs?[index];
        final author = worklog?.author;
        final started = worklog?.started;

        return Card(
          child: ListTile(
            title: Text('${author?.displayName}'),
            subtitle: Text('${worklog?.timeSpent} | ${started.toString()}'),
            leading: CircleAvatar(
              backgroundImage:
                  Image.network('${worklog?.author?.avatarUrls?.big}').image,
            ),
            trailing: IconButton(
              icon: const Icon(
                Icons.delete_outline,
              ),
              onPressed: () => onDeleteData(worklog!),
            ),
          ),
        );
      },
    );
  }
}
