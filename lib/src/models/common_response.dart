class Common {
  String? name;
  String? self;
  String? id;

  Common({this.name, this.self, this.id});

  Common.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    self = json['self'];
    id = json["id"];
  }
}

class Author {
  String? self;
  String? name;
  String? key;
  String? emailAddress;
  AvatarUrls? avatarUrls;
  String? displayName;
  bool? active;
  String? timeZone;

  Author(
      {this.self,
      this.name,
      this.key,
      this.emailAddress,
      this.avatarUrls,
      this.displayName,
      this.active,
      this.timeZone});

  Author.fromJson(Map<String, dynamic> json) {
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

class AvatarUrls {
  String? big;
  String? medium;
  String? small;
  String? xsmall;

  AvatarUrls({this.big, this.medium, this.small, this.xsmall});

  AvatarUrls.fromJson(Map<String, dynamic> json) {
    big = json['48x48']; //big
    medium = json['32x32']; //medium
    small = json['24x24']; //small
    xsmall = json['16x16']; //xsmall
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['48x48'] = big;
    data['32x32'] = medium;
    data['24x24'] = small;
    data['16x16'] = xsmall;

    return data;
  }
}
