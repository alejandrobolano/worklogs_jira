import 'package:flutter_test/flutter_test.dart';
import 'package:worklogs_jira/src/models/worklog_response.dart';

Map<String, dynamic> worklogJson(dynamic comment) => {
      'comment': comment,
      'created': '2026-10-02T10:20:01.024+0200',
      'updated': '2026-10-02T10:20:01.024+0200',
      'started': '2026-10-01T10:00:00.000+0200',
      'timeSpent': '8m',
      'timeSpentSeconds': 480,
      'id': '1741478',
      'issueId': '1133105',
    };

void main() {
  test('preserves Jira v2 string and null comments', () {
    for (final comment in ['Comentario v2\nSegunda línea', '', null]) {
      expect(Worklog.fromJson(worklogJson(comment)).comment, comment);
    }
  });

  test('parses Jira v3 ADF comments through WorklogResponse', () {
    final response = WorklogResponse.fromJson({
      'startAt': 0,
      'maxResults': 20,
      'total': 1,
      'worklogs': [
        worklogJson({
          'type': 'doc',
          'version': 1,
          'content': [
            {
              'type': 'paragraph',
              'content': [
                {'type': 'text', 'text': 'Trabajo '},
                {
                  'type': 'text',
                  'text': 'completado',
                  'marks': [
                    {'type': 'strong'}
                  ],
                },
                {'type': 'hardBreak'},
                {'type': 'text', 'text': 'Revisado'},
              ],
            },
            {
              'type': 'bulletList',
              'content': [
                {
                  'type': 'listItem',
                  'content': [
                    {
                      'type': 'paragraph',
                      'content': [
                        {'type': 'text', 'text': 'Pruebas correctas'},
                      ],
                    },
                  ],
                },
              ],
            },
          ],
        }),
      ],
    });

    final worklog = response.worklogs!.single!;
    expect(worklog.comment, 'Trabajo completado\nRevisado\nPruebas correctas');
    expect(worklog.id, '1741478');
    expect(worklog.timeSpentSeconds, 480);
    expect(worklog.started, DateTime.utc(2026, 10, 1, 8));
    expect(response.total, 1);
  });

  test('parses empty Jira v3 ADF comments', () {
    for (final content in [
      <Map<String, dynamic>>[],
      [
        {'type': 'paragraph', 'content': []}
      ],
    ]) {
      final worklog = Worklog.fromJson(worklogJson({
        'type': 'doc',
        'version': 1,
        'content': content,
      }));
      expect(worklog.comment, '');
    }
  });
}
