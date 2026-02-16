# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.4.0] - 2026-02-16

### Added
- Automatic update checker on app startup
- Autocomplete for project prefix from Jira API with dropdown selector
- Load user projects from Jira automatically in settings
- Centralized GitHub configuration (app_config.dart)
- Update notification dialog with release notes

### Improved
- Unified Jira API version across the application (v2)
- Auto-uppercase and add dash to project prefix on selection
- Better error handling for Jira API calls
- Simplified project loading logic

### Changed
- Moved GitHub repository configuration to centralized config file
- Standardized Jira API usage throughout the app

## [2.3.0] - 2026-01-29

### Added
- Add pie chart and bar chart visualizations
- Implement horizontal calendar showing daily logged tasks
- Add date range filtering for dashboard
- Remember last logged date in date picker
- Center window on startup with minimum size 720×720

### Improved
- Improve responsive layout for input fields
- Add vertical scroll for dashboard content

## [2.2.5] - 2024-08-22

### Added
- Adapt Dashboard from email

## [2.2.3] - 2024-03-05

### Fixed
- Minor fixes

## [2.2.2] - 2024-02-22

### Removed
- Delete password option

## [2.2.1] - 2024-02-13

### Changed
- Initial stable release

---

## How to Release

1. Update version in `pubspec.yaml`
2. Update `CHANGELOG.md` with new changes
3. Commit changes: `git commit -am "Release v2.x.x"`
4. Create tag: `git tag v2.x.x`
5. Push with tags: `git push origin main --tags`
6. Create Release on GitHub with tag and CHANGELOG content
