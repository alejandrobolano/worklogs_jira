import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:worklogs_jira/src/helper/date_helper.dart';
import 'package:worklogs_jira/src/helper/widget_helper.dart';
import '../../models/worklog_response.dart';
import 'package:worklogs_jira/src/localization/app_localizations.dart';

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

        return Card(
          child: ListTile(
            onTap: worklog == null
                ? null
                : () => _settingModalBottomSheet(context, worklog),
            title: Text(author?.displayName ?? ''),
            subtitle: Text(
                '${worklog?.timeSpent ?? ''} | ${started?.toLocal() ?? ''}'),
            leading: CircleAvatar(
              backgroundColor: WidgetHelper.getRandomColor(),
              child: Text(_splitNameToInitials(author?.displayName ?? '')),
            ),
            trailing: IconButton(
              icon: const Icon(
                Icons.delete_outline,
              ),
              onPressed: worklog == null ||
                      worklog.id == null ||
                      worklog.issueId == null
                  ? null
                  : () => onDeleteData(worklog),
            ),
          ),
        );
      },
    );
  }

  String _splitNameToInitials(String fullName) {
    final words = fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .take(2);
    return words.isEmpty
        ? '?'
        : words.map((word) => word.characters.first.toUpperCase()).join();
  }

  void _settingModalBottomSheet(context, Worklog worklog) {
    final createdDate = worklog.created == null
        ? ''
        : DateHelper.formatDate(worklog.created!.toLocal());
    final updatedDate = worklog.updated == null
        ? ''
        : DateHelper.formatDate(worklog.updated!.toLocal());
    final startedDate = worklog.started == null
        ? ''
        : DateHelper.formatDate(worklog.started!.toLocal());
    var urlImage = worklog.author?.avatarUrls?.big;
    final avatarUri = Uri.tryParse(urlImage ?? '');
    final authorName = worklog.author?.name;
    if (urlImage != null &&
        urlImage.isNotEmpty &&
        avatarUri != null &&
        authorName != null &&
        authorName.isNotEmpty &&
        !avatarUri.queryParameters.containsKey('ownerId')) {
      urlImage = avatarUri.replace(queryParameters: {
        ...avatarUri.queryParameters,
        'ownerId': authorName,
      }).toString();
    }

    showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        showDragHandle: true,
        builder: (BuildContext bc) {
          return SafeArea(
            top: false,
            child: ConstrainedBox(
              constraints:
                  BoxConstraints(maxHeight: MediaQuery.sizeOf(bc).height * 0.8),
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Center(
                        heightFactor: 2,
                        child: CircleAvatar(
                          radius: 32,
                          child: urlImage == null || urlImage.isEmpty
                              ? Text(_splitNameToInitials(
                                  worklog.author?.displayName ?? ''))
                              : ClipOval(
                                  child: CachedNetworkImage(
                                      imageUrl: urlImage,
                                      width: 64,
                                      height: 64,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) =>
                                          const Icon(Icons.person_outline),
                                      errorWidget: (context, url, error) =>
                                          const Icon(Icons.person_outline))),
                        )),
                    ListTile(
                        leading: const Icon(Icons.person_outline),
                        title: Text(worklog.author?.displayName ?? ''),
                        onTap: () => {}),
                    ListTile(
                        leading: const Icon(Icons.timelapse_outlined),
                        title: Text(
                            '${AppLocalizations.of(context)?.timeSpent}: ${worklog.timeSpent ?? ''}')),
                    ListTile(
                        leading: const Icon(Icons.calendar_today_rounded),
                        title: Text(
                            '${AppLocalizations.of(context)?.startedLog}: $startedDate')),
                    ListTile(
                        leading: const Icon(Icons.text_snippet_outlined),
                        title: Text(
                            '${AppLocalizations.of(context)?.comment}: ${worklog.comment ?? ''}')),
                    ListTile(
                        leading: const Icon(Icons.calendar_today_outlined),
                        title: Text(
                            '${AppLocalizations.of(context)?.created}: $createdDate')),
                    ListTile(
                        leading: const Icon(Icons.calendar_today_outlined),
                        title: Text(
                            '${AppLocalizations.of(context)?.updated}: $updatedDate')),
                  ],
                ),
              ),
            ),
          );
        });
  }
}
