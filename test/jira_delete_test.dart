import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:worklogs_jira/src/jira/jira_service.dart';

void main() {
  for (final version in [2, 3]) {
    test('DELETE v$version uses issueId and worklog id and accepts 204',
        () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));
      final requestHandled = server.first.then((request) async {
        final path = request.uri.path;
        final method = request.method;
        await request.drain();
        request.response.statusCode = HttpStatus.noContent;
        await request.response.close();
        return [method, path];
      });
      final response = await JiraService().deleteData(
          'http://${server.address.host}:${server.port}/rest/api/$version/issue/',
          'Basic test',
          '1741478',
          '1133105');
      expect(await requestHandled,
          ['DELETE', '/rest/api/$version/issue/1133105/worklog/1741478']);
      expect(response.statusCode, 204);
      expect(response.body, isEmpty);
    });
  }
}
