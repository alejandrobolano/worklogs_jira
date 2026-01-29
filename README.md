# Worklogs Jira

This is a small project to log works in Jira. It is based on consuming the Jira API to get, post, and delete data, you can view the [online documentation about issue-worklogs](https://developer.atlassian.com/cloud/jira/platform/rest/v3/api-group-issue-worklogs/#api-group-issue-worklogs).

**Version:** 2.2.5

**Author:** [Alejandro Bolaño](https://alejandrobolano.web.app)

## Features

- ✅ **Log worklogs** to Jira issues with hours and dates
- ✅ **Retrieve and display** existing worklogs for any issue
- ✅ **Delete worklogs** directly from the application
- ✅ **Bulk logging** with repetition feature (log same hours across multiple days)
- ✅ **Dashboard** with visual analytics:
  - Pie chart visualization
  - Bar chart visualization
  - Calendar view showing tasks logged by day
  - Date range filtering
- ✅ **Multi-language support** (Spanish and English)
- ✅ **Remember last logged date** for quick access
- ✅ **Configurable working hours** per day and working days
- ✅ **Encrypted credentials storage** (username/token are not stored in plain text)
- ✅ **Responsive design** adapting to different window sizes
- ✅ **Dark/Light theme support**

## Getting Started

This project is built with Flutter and follows the [simple app state management tutorial](https://flutter.dev/docs/development/data-and-backend/state-mgmt/simple).

For help getting started with Flutter development, view the [online documentation](https://flutter.dev/docs), which offers tutorials, samples, guidance on mobile development, and a full API reference.

### Prerequisites

- Flutter SDK (>=3.0.6 <4.0.0)
- Jira account with API access
- Personal Access Token or API Token from Jira

### Firebase Deploy

This project has web hosting configuration for Firebase. The web version is available at [https://worklogsjira.web.app/](https://worklogsjira.web.app/).

**Note:** Some functions may be incompatible with web due to CORS restrictions. The Windows desktop application is recommended for full functionality.

## Installation & Setup

### Initial Configuration

1. **Go to Settings:** Click on the settings icon in the app bar
2. **Enter credentials:**
   - **Jira URL:** Your company's Jira instance URL (e.g., `https://yourcompany.atlassian.net`)
   - **Email/Username:** Your Jira email or username
   - **Token:** Your Jira API token or password (recommended to use API token)
3. **Configure working hours:**
   - Set maximum daily hours
   - Select working days (Monday-Friday, etc.)
4. **Optional settings:**
   - Issue prefix (e.g., "PROJ-" to auto-fill)
   - Theme preference (System/Light/Dark)

**Security Note:** All credentials are encrypted before storage. They are never stored in plain text.

## Usage

### Main Screen (Worklog Management)

**Load a task:**
- Enter issue key (e.g., `PROJ-123`)
- Click the refresh button to view existing worklogs

**Log hours:**
- **Issue:** Enter the issue key
- **Start Date:** Select the date (remembers last logged date)
- **Hours:** Enter hours worked (decimal format, e.g., 2.5)
- **Repetitions:** Number of consecutive working days to log (default: 1)
- Click the "Log" button to submit

**Features:**
- View all worklogs for an issue with details (author, time spent, dates)
- Delete worklogs by clicking the delete icon
- Last logged date is displayed at the bottom for reference

### Dashboard Screen

Access via the chart icon in the app bar.

**Features:**
- **Date Range Filter:** Select start and finish dates to filter worklogs
- **Visual Charts:** 
  - Pie chart: Shows hours distribution across issues
  - Bar chart: Compare hours per issue
  - Toggle charts via the menu icon
- **Two view modes:**
  - **List View:** Traditional card-based list of issues
  - **Table View:** Calendar-style horizontal layout showing tasks grouped by day
- **Interactive:** Click on any issue to open it in Jira

The calendar view displays:
- Each day as a column
- Day of week and date
- Total hours logged that day
- All tasks logged with key, summary, hours, and status

## Supported Platforms

### Windows Desktop App ✅ (Recommended)

Full functionality with no CORS restrictions.

[Download Windows App](http://worklogsjira.smarttechlite.com/)

**Features:**
- Minimum window size: 720x720
- Opens centered on screen
- Resizable interface
- Native Windows integration

### Web App ⚠️ (Limited)

Available at [https://worklogsjira.web.app/](https://worklogsjira.web.app/)

**Limitations:** Some Jira API functions may not work due to browser CORS policies. The Windows desktop application is recommended for full functionality.

## Technologies Used

- **Flutter:** UI framework
- **Dart:** Programming language
- **fl_chart:** Chart visualization library
- **shared_preferences:** Local data persistence (encrypted)
- **http:** HTTP client for Jira API
- **intl:** Internationalization and date formatting
- **Firebase Hosting:** Web deployment

## Development

### Project Structure

```
lib/
├── main.dart
├── src/
│   ├── app.dart
│   ├── dashboard/         # Analytics and charts
│   │   ├── charts/
│   │   ├── logged_tasks_table.dart
│   │   ├── dashboard_view.dart
│   │   └── dashboard_controller.dart
│   ├── jira/              # Jira integration
│   │   ├── jira_service.dart
│   │   ├── jira_controller.dart
│   │   └── jira_view.dart
│   ├── settings/          # Configuration
│   │   ├── settings_view.dart
│   │   ├── settings_controller.dart
│   │   └── settings_service.dart
│   ├── models/            # Data models
│   ├── helper/            # Utility functions
│   └── localization/      # Translations (es, en)
```

### Build Commands

**Windows:**
```bash
flutter build windows
```

**Web:**
```bash
flutter build web
```

**Run in development:**
```bash
flutter run -d windows
```

## Contributing

Contributions are welcome! Feel free to submit issues or pull requests.

## License

This project is open source and available for personal and commercial use.

## Support

For issues or questions, please visit the [GitHub repository](https://github.com/alejandrobolano/worklogs_jira) or contact the author.


