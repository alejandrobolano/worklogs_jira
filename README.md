# Worklogs Jira

This is a small project to log works in Jira. It is based on consuming the Jira API to get, post, and delete data, you can view the [online documentation about issue-worklogs](https://developer.atlassian.com/cloud/jira/platform/rest/v3/api-group-issue-worklogs/#api-group-issue-worklogs).
It contains two startup files that vary in configuration depending on whether it is for a development or production environment.

Information about author: [Alejandro Bolaño](https://alejandrobolano.web.app)

## Getting Started

This project is a starting point for a Flutter application that follows the
[simple app state management
tutorial](https://flutter.dev/docs/development/data-and-backend/state-mgmt/simple).

For help getting started with Flutter development, view the
[online documentation](https://flutter.dev/docs), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Using

Firstly, before using it, you must go to the settings section and insert the username and password, and then save it. **These data are not stored in plain text**. Afterwards, a message will appear confirming that the authorization is saved, allowing you to use it within the application.

On the main screen, you can:

* Insert a task and click the refresh button with the associated icon to perform a 'get' operation and view the related work.
* Insert a task + start date (it shouldn't be Saturday or Sunday) + hours worked + repetition (default: 1). This way, you can log that task, and it will repeat based on the specified repetition.
* See different items about the task, like owner, timespent, and other.

Dashboard screen, you can:

* To see all issues logged between some range.
* To see different charts and to appreciate all issues graphically.

## VSCode

If you want to compile using VSCode, it is recommended to have a launch.json file to facilitate deployment, as shown below.
```
{
    "version": "2.0.6",
    "configurations": [
      {
        "name": "Flutter: Development",
        "request": "launch",
        "type": "dart",
        "program": "lib/main_dev.dart",
        "args": ["development"] //"args": ["--flavor", "development"]
      },
      {
        "name": "Flutter: Production",
        "request": "launch",
        "type": "dart",
        "program": "lib/main.dart",
        "args": ["production"]
      }
    ]
  }
```

