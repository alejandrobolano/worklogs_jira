import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';

class JiraService {
  Future<Response> getData(String url, basicAuth, issue) async {
    final String finalUrl = '$url$issue/worklog';
    final response = await http.get(
      Uri.parse(finalUrl),
      headers: {'Authorization': basicAuth, 'Content-Type': 'application/json'},
    );
    return response;
  }

  Future<Response> postData(String url, basicAuth, issue, hours, date) async {
    final String finalUrl = '$url$issue/worklog';

    final Map<String, dynamic> requestBody = {
      'comment': '',
      'timeSpent': hours.toStringAsPrecision(2),
      'started': '${date}T08:00:00.000+0000'
    };

    final response = await http.post(
      Uri.parse(finalUrl),
      headers: {'Authorization': basicAuth, 'Content-Type': 'application/json'},
      body: json.encode(requestBody),
    );

    return response;
  }

  Future<Response> deleteData(String url, basicAuth, id, issueId) async {
    final String finalUrl = '$url$issueId/worklog/$id';
    final response = await http.delete(
      Uri.parse(finalUrl),
      headers: {'Authorization': basicAuth, 'Content-Type': 'application/json'},
    );
    return response;
  }
}
