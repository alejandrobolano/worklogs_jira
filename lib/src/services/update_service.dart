import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:worklogs_jira/src/config/app_config.dart';

class UpdateService {
  
  Future<UpdateInfo?> checkForUpdates() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      
      final response = await http.get(
        Uri.parse('https://api.github.com/repos/${AppConfig.githubRepoPath}/releases/latest'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final latestVersion = _cleanVersion(data['tag_name'] ?? '');
        final currentClean = _cleanVersion(currentVersion);
        
        if (_isNewerVersion(latestVersion, currentClean)) {
          return UpdateInfo(
            version: latestVersion,
            downloadUrl: data['html_url'] ?? '',
            releaseNotes: data['body'] ?? '',
            publishedAt: data['published_at'] ?? '',
          );
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  String _cleanVersion(String version) {
    return version.replaceFirst('v', '').trim();
  }

  bool _isNewerVersion(String latest, String current) {
    try {
      final latestParts = latest.split('.').map(int.parse).toList();
      final currentParts = current.split('.').map(int.parse).toList();

      for (int i = 0; i < 3; i++) {
        final latestNum = i < latestParts.length ? latestParts[i] : 0;
        final currentNum = i < currentParts.length ? currentParts[i] : 0;

        if (latestNum > currentNum) return true;
        if (latestNum < currentNum) return false;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}

class UpdateInfo {
  final String version;
  final String downloadUrl;
  final String releaseNotes;
  final String publishedAt;

  UpdateInfo({
    required this.version,
    required this.downloadUrl,
    required this.releaseNotes,
    required this.publishedAt,
  });
}
