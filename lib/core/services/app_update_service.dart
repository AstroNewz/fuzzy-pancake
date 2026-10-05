import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/app_constants.dart';
import '../theme/app_theme.dart';

/// Model representing an available APK update
class AppUpdateInfo {
  final String versionName;
  final int versionCode;
  final String downloadUrl;
  final String releaseNotes;
  final bool isMandatory;
  final String publishedBy;

  const AppUpdateInfo({
    required this.versionName,
    required this.versionCode,
    required this.downloadUrl,
    required this.releaseNotes,
    this.isMandatory = false,
    this.publishedBy = 'Ishan Narayan Shukla',
  });

  factory AppUpdateInfo.fromMap(Map<String, dynamic> map) {
    return AppUpdateInfo(
      versionName: map['version_name']?.toString() ?? '1.1.0',
      versionCode: (map['version_code'] as num?)?.toInt() ?? 2,
      downloadUrl: map['download_url']?.toString() ??
          'https://github.com/ishanshkla/SmashDeck/releases/latest',
      releaseNotes: map['release_notes']?.toString() ??
          '• New squad accounts added\n• Manual captain attendance\n• Squad Common Space & Events',
      isMandatory: (map['is_mandatory'] as bool?) ?? false,
      publishedBy: map['published_by']?.toString() ?? 'Ishan Narayan Shukla',
    );
  }
}

/// APK Update Service
class AppUpdateService {
  static const int currentVersionCode = 1;
  static const String currentVersionName = AppConstants.appVersion; // 1.0.0

  static Future<AppUpdateInfo?> fetchLatestUpdate(
      SupabaseClient client) async {
    try {
      final response = await client
          .from('app_updates')
          .select()
          .order('version_code', ascending: false)
          .limit(1)
          .maybeSingle()
          .timeout(const Duration(seconds: 4));

      if (response != null) {
        return AppUpdateInfo.fromMap(response);
      }
    } catch (_) {}
    return null;
  }

  /// Automatically check for updates on startup or manual button tap
  static Future<void> checkForUpdates(
    BuildContext context,
    SupabaseClient client, {
    bool isManualCheck = false,
  }) async {
    final update = await fetchLatestUpdate(client);

    if (!context.mounted) return;

    if (update != null && update.versionCode > currentVersionCode) {
      showDialog(
        context: context,
        barrierDismissible: !update.isMandatory,
        builder: (_) => AppUpdateDialog(updateInfo: update),
      );
    } else if (isManualCheck) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle_outline,
                  color: AppTheme.limeNeon, size: 20),
              SizedBox(width: 10),
              Text('You have the latest version of SmashDeck (v1.0.0)!'),
            ],
          ),
          backgroundColor: Color(0xFF131D18),
        ),
      );
    }
  }

  /// Publish a new APK update entry (Used by Master Admin Ishan Narayan Shukla)
  static Future<bool> publishUpdate({
    required SupabaseClient client,
    required String versionName,
    required int versionCode,
    required String downloadUrl,
    required String releaseNotes,
    bool isMandatory = false,
    required String publisherName,
  }) async {
    try {
      await client.from('app_updates').insert({
        'version_name': versionName,
        'version_code': versionCode,
        'download_url': downloadUrl,
        'release_notes': releaseNotes,
        'is_mandatory': isMandatory,
        'published_by': publisherName,
      });
      return true;
    } catch (e) {
      debugPrint('[AppUpdateService] Publish error: $e');
      return false;
    }
  }
}

/// Sleek APK Update Alert Dialog
class AppUpdateDialog extends StatelessWidget {
  final AppUpdateInfo updateInfo;

  const AppUpdateDialog({super.key, required this.updateInfo});

  Future<void> _launchDownloadUrl(BuildContext context) async {
    try {
      final uri = Uri.parse(updateInfo.downloadUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(uri);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open download link: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF121A15),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
              color: AppTheme.limeNeon.withValues(alpha: 0.6), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: AppTheme.limeNeon.withValues(alpha: 0.25),
              blurRadius: 30,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon & Header
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.limeNeon.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.system_update_alt_rounded,
                      color: AppTheme.limeNeon, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'New Update Ready! 🎉',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.textWhite,
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.limeNeon,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'v${updateInfo.versionName}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: Colors.black,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            '(Current: v1.0.0)',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // Release Notes Box
            const Text(
              "WHAT'S NEW IN THIS BUILD:",
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: AppTheme.limeNeon,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.cardDarker,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.borderDark),
              ),
              child: Text(
                updateInfo.releaseNotes,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.white,
                  height: 1.4,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Download Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.limeNeon,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.download_rounded, size: 20),
                label: const Text(
                  'Download & Install APK',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
                ),
                onPressed: () => _launchDownloadUrl(context),
              ),
            ),

            if (!updateInfo.isMandatory) ...[
              const SizedBox(height: 10),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Remind Me Later',
                    style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textMuted,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
