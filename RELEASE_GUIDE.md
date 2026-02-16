# 🚀 GitHub Releases Management Guide

## 📋 Initial Setup

### 1. Update GitHub configuration in `app_config.dart`

Edit the file `lib/src/config/app_config.dart`:

```dart
class AppConfig {
  // GitHub repository (format: 'user/repository')
  static const String githubUser = 'your_username';  // ← Change this
  static const String githubRepo = 'worklogs_jira';
  
  // ... rest of the code
}
```

This configuration is automatically used in:
- ✅ Update checking
- ✅ GitHub button in the app
- ✅ Repository links

---

## 📝 Release Creation Process

### Step 1: Update Version

1. **Edit `pubspec.yaml`:**
   ```yaml
   version: 2.4.0  # Increment the version
   ```

2. **Edit `pubspec.yaml` (msix_config section):**
   ```yaml
   msix_version: 2.4.0.0  # Must match
   ```

### Step 2: Update CHANGELOG.md

Add a new section at the beginning of the file:

```markdown
## [2.4.0] - 2026-XX-XX

### Added
- New feature X
- New feature Y

### Fixed
- Bug fix Z

### Changed
- Changed behavior W
```

### Step 3: Build the Application

```bash
# Build for Windows
flutter build windows --release

# Create MSIX installer
flutter pub run msix:create
```

The installer will be at: `build\windows\x64\runner\Release\`

### Step 4: Commit and Tag

```bash
git add .
git commit -m "Release v2.4.0"
git tag v2.4.0
git push origin main --tags
```

### Step 5: Create Release on GitHub

1. Go to your repository on GitHub
2. Click on **"Releases"** → **"Draft a new release"**
3. **Choose a tag:** Select `v2.4.0` (the tag you created)
4. **Release title:** `WorklogsJira v2.4.0`
5. **Description:** Copy the relevant content from CHANGELOG.md
6. **Attach binaries:** Upload the `.msix` file from `build\windows\x64\runner\Release\`
7. Click **"Publish release"**

---

## ✅ Automatic Verification

Once the release is published:

1. Users will open the app
2. 2 seconds after startup, it will automatically check for a new version
3. If available, a dialog will show:
   - New version number
   - Release notes
   - Download button

---

## 🔍 GitHub Release Structure Example

**Tag:** `v2.4.0`

**Title:** `WorklogsJira v2.4.0`

**Description:**
```markdown
## 🎉 What's New

### Added
- Autocomplete for project prefix from Jira API
- Load user projects from Jira with dropdown selector
- Automatic update checker on startup

### Improved
- Better error handling for Jira API calls
- Enhanced responsive layout

### Fixed
- Issue with prefix not converting to uppercase

## 📥 Installation

Download the `.msix` installer below and run it to update your existing installation.

**Full Changelog**: https://github.com/YOUR_USER/worklogs_jira/compare/v2.3.0...v2.4.0
```

**Files:** Attach `WorklogsJiraSetup.msix`

---

## 📌 Important Notes

- **Semantic Versioning:** Use `MAJOR.MINOR.PATCH` format
  - `MAJOR`: Breaking changes
  - `MINOR`: New backward-compatible features
  - `PATCH`: Bug fixes

- **Tag Format:** Always use `v` before the number (e.g., `v2.4.0`)

- **Assets:** Always upload the `.msix` file to the release so users can download it

---

## 🛠️ Troubleshooting

### App doesn't detect updates

1. Verify the repository in `app_config.dart` is correct
2. Make sure the release is published (not in draft)
3. Verify the tag has format `v2.x.x`
4. Check user's internet connection

### Build error

```bash
flutter clean
flutter pub get
flutter build windows --release
```

---

## 📚 Resources

- [GitHub Releases Documentation](https://docs.github.com/en/repositories/releasing-projects-on-github)
- [Semantic Versioning](https://semver.org/)
- [Keep a Changelog](https://keepachangelog.com/)
