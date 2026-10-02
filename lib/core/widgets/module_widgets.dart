import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../network/club_module_store.dart';
import '../theme/app_theme.dart';

Future<void> runClubAction(
    BuildContext context, Future<void> Function() action) async {
  try {
    await action();
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceFirst('Bad state: ', ''))));
    }
  }
}

class ModuleSyncBar extends StatelessWidget {
  const ModuleSyncBar({super.key, required this.store});
  final ClubModuleStore<dynamic> store;
  @override
  Widget build(BuildContext context) => ValueListenableBuilder<String>(
      valueListenable: store.status,
      builder: (context, value, _) => ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(
                value == 'Live club sync'
                    ? Icons.cloud_done_outlined
                    : Icons.cloud_off_outlined,
                size: 18,
                color: AppTheme.mintTeal),
            title: Text(value, style: AppTheme.bodySm),
            trailing: IconButton(
                tooltip: 'Sync club records',
                icon: const Icon(Icons.sync, size: 18),
                onPressed: () => runClubAction(context, store.sync)),
            onTap: !store.hasConflict
                ? null
                : () => showDialog<void>(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                          title: const Text('Another captain made changes'),
                          content: const Text(
                              'Export your local copy before loading the current club version. Loading replaces this device’s conflicting edits.'),
                          actions: [
                            TextButton(
                                onPressed: () => Clipboard.setData(
                                    ClipboardData(
                                        text: jsonEncode(
                                            store.exportedSnapshot))),
                                child: const Text('Copy local records')),
                            FilledButton(
                                onPressed: () async {
                                  await runClubAction(
                                      context, store.useCloudVersion);
                                  if (dialogContext.mounted) {
                                    Navigator.pop(dialogContext);
                                  }
                                },
                                child: const Text('Load club version'))
                          ],
                        )),
          ));
}
