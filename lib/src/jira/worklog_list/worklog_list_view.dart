import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:worklogs_jira/src/helper/date_helper.dart';
import 'package:worklogs_jira/src/helper/widget_helper.dart';
import '../../models/worklog_response.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class WorklogListView extends StatelessWidget {
  final WorklogResponse worklogResponse;
  final Function(Worklog) onDeleteData;

  const WorklogListView(
      {super.key, required this.worklogResponse, required this.onDeleteData});

  @override
  Widget build(BuildContext context) {
    if (worklogResponse.worklogs != null && worklogResponse.worklogs!.isEmpty) {
      return ListTile(
        leading: const Icon(Icons.access_alarms),
        title: Text(AppLocalizations.of(context)!.issueEmpty),
      );
    }
    return ListView.builder(
      restorationId: 'WorklogListView',
      itemCount: worklogResponse.worklogs != null
          ? worklogResponse.worklogs?.length
          : 0,
      itemBuilder: (BuildContext context, int index) {
        final worklog = worklogResponse.worklogs?[index];
        final author = worklog?.author;
        final started = worklog?.started;
        var urlImage = worklog?.author?.avatarUrls?.big;
        urlImage = urlImage!.contains("ownerId")
            ? worklog?.author?.avatarUrls?.big
            : "${worklog?.author?.avatarUrls!.big}&ownerId=${worklog?.author?.name}";

        return Card(
          child: ListTile(
            onTap: () => _settingModalBottomSheet(context, worklog!),
            title: Text('${author?.displayName}'),
            subtitle: Text('${worklog?.timeSpent} | ${started.toString()}'),
            leading: CircleAvatar(
              backgroundColor: WidgetHelper.getRandomColor(),
              child: Text(_splitNameToInitials('${author?.displayName}')),
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

  String _splitNameToInitials(String fullName) {
    List<String> words = fullName.split(' ');
    String first = words[0];
    String second = words[1];
    return first[0].toUpperCase() + second[0].toUpperCase();
  }

  void _settingModalBottomSheet(context, Worklog worklog) {
    final createdDate = DateHelper.formatDate(worklog.created!.toUtc());
    final updatedDate = DateHelper.formatDate(worklog.updated!.toUtc());
    final startedDate = DateHelper.formatDate(worklog.started!.toUtc());
    var urlImage = worklog.author?.avatarUrls?.big;
    urlImage = urlImage!.contains("ownerId")
        ? worklog.author?.avatarUrls?.big
        : "${worklog.author?.avatarUrls!.big}&ownerId=${worklog.author?.name}";

    showModalBottomSheet(
        context: context,
        builder: (BuildContext bc) {
          return Wrap(
            children: <Widget>[
              Center(
                  heightFactor: 2,
                  child: CachedNetworkImage(
                      imageUrl: '$urlImage',
                      errorWidget: (context, url, error) =>
                          const Icon(Icons.error))),
              ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: Text('${worklog.author!.displayName}'),
                  onTap: () => {}),
              ListTile(
                  leading: const Icon(Icons.timelapse_outlined),
                  title: Text(
                      '${AppLocalizations.of(context)?.timeSpent}: ${worklog.timeSpent}')),
              ListTile(
                  leading: const Icon(Icons.calendar_today_rounded),
                  title: Text(
                      '${AppLocalizations.of(context)?.startedLog}: $startedDate')),
              ListTile(
                  leading: const Icon(Icons.text_snippet_outlined),
                  title: Text(
                      '${AppLocalizations.of(context)?.comment}: ${worklog.comment}')),
              ListTile(
                  leading: const Icon(Icons.calendar_today_outlined),
                  title: Text(
                      '${AppLocalizations.of(context)?.created}: $createdDate')),
              ListTile(
                  leading: const Icon(Icons.calendar_today_outlined),
                  title: Text(
                      '${AppLocalizations.of(context)?.updated}: $updatedDate')),
            ],
          );
        });
  }
}
