import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';

class JiraService {
  Future<Response> getData(String url, basicAuth) async {
    final response = await http.get(
      Uri.parse(url),
      headers: buildHeader(basicAuth),
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
    final response =
        await http.delete(Uri.parse(finalUrl), headers: buildHeader(basicAuth));
    return response;
  }

  Map<String, String> buildHeader(basicAuth) {
    return {
      'Authorization': basicAuth,
      'Content-Type': 'application/json',
      "Access-Control-Allow-Origin": "*",
      "Access-Control-Allow-Methods": "GET,PUT,PATCH,POST,DELETE",
      "Access-Control-Allow-Headers":
          "Origin, X-Requested-With, Content-Type, Accept",
      'Access-Control-Allow-Credentials': 'true'
    };
  }
}
