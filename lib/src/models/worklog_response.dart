import 'package:worklogs_jira/src/models/common_response.dart';

class WorklogResponse {
  int? startAt;
  int? maxResults;
  int? total;
  List<Worklog?>? worklogs;

  WorklogResponse({this.startAt, this.maxResults, this.total, this.worklogs});

  WorklogResponse.fromJson(Map<String, dynamic> json) {
    startAt = json['startAt'];
    maxResults = json['maxResults'];
    total = json['total'];
    if (json['worklogs'] != null) {
      worklogs = <Worklog>[];
      json['worklogs'].forEach((v) {
        worklogs!.add(Worklog.fromJson(v));
      });
    }
  }
}

class Worklog {
  String? self;
  Author? author;
  UpdateAuthor? updateAuthor;
  String? comment;
  DateTime? created;
  DateTime? updated;
  DateTime? started;
  String? timeSpent;
  int? timeSpentSeconds;
  String? id;
  String? issueId;

  Worklog(
      {this.self,
      this.author,
      this.updateAuthor,
      this.comment,
      this.created,
      this.updated,
      this.started,
      this.timeSpent,
      this.timeSpentSeconds,
      this.id,
      this.issueId});

  Worklog.fromJson(Map<String, dynamic> json) {
    self = json['self'];
    author = json['author'] != null ? Author?.fromJson(json['author']) : null;
    updateAuthor = json['updateAuthor'] != null
        ? UpdateAuthor?.fromJson(json['updateAuthor'])
        : null;
    comment = json['comment'];
    created = DateTime.parse(json['created']);
    updated = DateTime.parse(json['updated']);
    started = DateTime.parse(json['started']);
    timeSpent = json['timeSpent'];
    timeSpentSeconds = json['timeSpentSeconds'];
    id = json['id'];
    issueId = json['issueId'];
  }
}

class UpdateAuthor {
  String? self;
  String? name;
  String? key;
  String? emailAddress;
  AvatarUrls? avatarUrls;
  String? displayName;
  bool? active;
  String? timeZone;

  UpdateAuthor(
      {this.self,
      this.name,
      this.key,
      this.emailAddress,
      this.avatarUrls,
      this.displayName,
      this.active,
      this.timeZone});

  UpdateAuthor.fromJson(Map<String, dynamic> json) {
    self = json['self'];
    name = json['name'];
    key = json['key'];
    emailAddress = json['emailAddress'];
    avatarUrls = json['avatarUrls'] != null
        ? AvatarUrls?.fromJson(json['avatarUrls'])
        : null;
    displayName = json['displayName'];
    active = json['active'];
    timeZone = json['timeZone'];
  }
}
