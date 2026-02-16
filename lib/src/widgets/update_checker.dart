import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:worklogs_jira/src/services/update_service.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class UpdateChecker extends StatefulWidget {
  final Widget child;

  const UpdateChecker({super.key, required this.child});

  @override
  State<UpdateChecker> createState() => _UpdateCheckerState();
}

class _UpdateCheckerState extends State<UpdateChecker> {
  final UpdateService _updateService = UpdateService();
  bool _hasChecked = false;

  @override
  void initState() {
    super.initState();
    _checkForUpdates();
  }

  Future<void> _checkForUpdates() async {
    if (_hasChecked) return;
    _hasChecked = true;
    await Future.delayed(const Duration(seconds: 2));

    final updateInfo = await _updateService.checkForUpdates();
    
    if (updateInfo != null && mounted) {
      _showUpdateDialog(updateInfo);
    }
  }

  void _showUpdateDialog(UpdateInfo updateInfo) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.system_update, color: Colors.blue),
              const SizedBox(width: 10),
              Text(AppLocalizations.of(context)?.updateAvailable ?? 
                   'Update Available'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${AppLocalizations.of(context)?.newVersion ?? "New version"}: ${updateInfo.version}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context)?.releaseNotes ?? 
                  'Release Notes:',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    updateInfo.releaseNotes.isNotEmpty
                        ? updateInfo.releaseNotes
                        : AppLocalizations.of(context)?.noReleaseNotes ?? 
                          'No release notes available',
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(AppLocalizations.of(context)?.later ?? 'Later'),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                final uri = Uri.parse(updateInfo.downloadUrl);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
                if (mounted) {
                  Navigator.of(context).pop();
                }
              },
              icon: const Icon(Icons.download),
              label: Text(AppLocalizations.of(context)?.download ?? 'Download'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
