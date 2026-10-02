import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';

class JiraService {
  Future<Response> getData(String url, String basicAuth) async {
    final response = await http.get(
      Uri.parse(url),
      headers: buildHeader(basicAuth),
    );
    return response;
  }

  // Worklogs in both API versions and legacy searches use offset pagination.
  Future<Response> getPagedData(String url, String basicAuth, String listKey,
      {Response? firstResponse}) async {
    final baseUri = Uri.parse(url);
    var response = firstResponse ?? await getData(url, basicAuth);
    final allItems = <dynamic>[];
    var offset = 0;
    while (true) {
      if (response.statusCode != 200) return response;
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final items = data[listKey] as List<dynamic>? ?? [];
      allItems.addAll(items);
      final nextOffset = (data['startAt'] as int? ?? offset) + items.length;
      final total = data['total'] as int? ?? nextOffset;
      if (nextOffset >= total) {
        if (offset == 0) return response;
        data[listKey] = allItems;
        data['startAt'] = 0;
        data['maxResults'] = allItems.length;
        return Response.bytes(
            utf8.encode(jsonEncode(data)), response.statusCode,
            headers: {
              ...response.headers,
              'content-type': 'application/json; charset=utf-8',
            },
            reasonPhrase: response.reasonPhrase);
      }
      if (items.isEmpty || nextOffset <= offset) {
        throw const FormatException('Jira pagination did not advance');
      }
      offset = nextOffset;
      final uri = baseUri.replace(queryParameters: {
        ...baseUri.queryParameters,
        'startAt': '$offset',
        'maxResults': '100',
      });
      response = await getData(uri.toString(), basicAuth);
    }
  }

  Future<Response> postData(String url, String basicAuth, String issue,
      double hours, String date) async {
    if (!hours.isFinite || hours <= 0 || (hours * 3600).round() <= 0) {
      throw ArgumentError('Worklog hours must be positive and finite');
    }
    final String finalUrl = '$url$issue/worklog';

    final Map<String, dynamic> requestBody = {
      'comment': url.contains('/rest/api/3/')
          ? {
              'type': 'doc',
              'version': 1,
              'content': [
                {'type': 'paragraph', 'content': []}
              ]
            }
          : '',
      'timeSpentSeconds': (hours * 3600).round(),
      'started': '${date}T08:00:00.000+0000'
    };

    final response = await http.post(
      Uri.parse(finalUrl),
      headers: {'Authorization': basicAuth, 'Content-Type': 'application/json'},
      body: json.encode(requestBody),
    );

    return response;
  }

  Future<Response> deleteData(
      String url, String basicAuth, String id, String issueId) async {
    final String finalUrl = '$url$issueId/worklog/$id';
    final response =
        await http.delete(Uri.parse(finalUrl), headers: buildHeader(basicAuth));
    return response;
  }

  Map<String, String> buildHeader(String basicAuth) {
    return {
      'Authorization': basicAuth,
      'Content-Type': 'application/json',
      "Access-Control-Allow-Origin": "*",
      "Access-Control-Allow-Methods": "GET,PUT,PATCH,POST,DELETE",
      "Access-Control-Allow-Headers":
          "Origin, X-Requested-With, Content-Type, Accept",
      'Access-Control-Allow-Credentials': 'true',
      'Accept': 'application/json'
    };
  }
}
