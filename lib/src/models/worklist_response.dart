import 'package:worklogs_jira/src/models/common_response.dart';

class WorklistResponse {
  String? expand;
  int? startAt;
  int? maxResults;
  int? total;
  List<Issues?>? issues;

  WorklistResponse({this.startAt, this.maxResults, this.total, this.issues});

  WorklistResponse.fromJson(Map<String, dynamic> json) {
    expand = json['expand'];
    startAt = json['startAt'];
    maxResults = json['maxResults'];
    total = json['total'];
    if (json['issues'] != null) {
      issues = <Issues>[];
      json['issues'].forEach((v) {
        issues!.add(Issues.fromJson(v));
      });
    }
  }
}

class Issues {
  String? self;
  Fields? fields;
  String? key;
  String? id;

  Issues({this.self, this.fields, this.key, this.id});

  Issues.fromJson(Map<String, dynamic> json) {
    self = json['self'];
    fields = json['fields'] != null ? Fields?.fromJson(json['fields']) : null;
    key = json['key'];
    id = json['id'];
  }
}

class Fields {
  String? summary;
  int? timespent;
  IssueType? issueType;
  Project? project;
  List<Issues?>? subtasks;
  Author? assignee;
  Status? status;

  Fields(
      {this.summary,
      this.timespent,
      this.issueType,
      this.project,
      this.subtasks,
      this.assignee,
      this.status});

  Fields.fromJson(Map<String, dynamic> json) {
    summary = json['summary'];
    timespent = json['timespent'];
    issueType = json['issuetype'] != null
        ? IssueType?.fromJson(json['issuetype'])
        : null;
    project =
        json['project'] != null ? Project?.fromJson(json['project']) : null;
    if (json['subtasks'] != null) {
      subtasks = <Issues>[];
      json['subtasks'].forEach((v) {
        subtasks!.add(Issues.fromJson(v));
      });
    }
    assignee =
        json['assignee'] != null ? Author?.fromJson(json['assignee']) : null;
    status = json['status'] != null ? Status?.fromJson(json['status']) : null;
  }
}

class IssueType extends Common {
  bool? subtask;

  IssueType({this.subtask});

  IssueType.fromJson(Map<String, dynamic> json) : super.fromJson(json) {
    subtask = json['subtask'];
  }
}

class Status {
  String? name;

  Status({this.name});

  Status.fromJson(Map<String, dynamic> json) {
    name = json['name'];
  }
}

class Project extends Common {
  Project.fromJson(Map<String, dynamic> json) : super.fromJson(json);
}
