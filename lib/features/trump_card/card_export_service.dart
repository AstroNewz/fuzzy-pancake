import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../../core/theme/app_theme.dart';
import 'card_export_downloader.dart';
import '../../core/services/file_export_service.dart';
import '../../core/widgets/module_widgets.dart';
import 'trump_card_model.dart';

/// Service responsible for rendering and exporting Trump Cards as high-resolution PNGs
/// Addresses ISSUE-005 (Cross-Platform Asset Export on Web & Mobile)
class CardExportService {
  /// Renders widget at [repaintKey] to high-DPI PNG byte buffer
  static Future<Uint8List?> capturePng({
    required GlobalKey repaintKey,
    double pixelRatio = 3.0,
  }) async {
    try {
      final boundary = repaintKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return null;

      final ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('CardExportService capture error: $e');
      return null;
    }
  }

  /// 1-Tap Export Workflow: captures PNG, triggers download, and displays export preview dialog
  static Future<void> exportAndShareCard({
    required BuildContext context,
    required GlobalKey repaintKey,
    required TrumpCardModel card,
  }) async {
    // Show quick progress feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppTheme.cardDark,
        duration: const Duration(seconds: 1),
        content: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppTheme.primaryNeon,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Rendering Ultra-HD card for ${card.fullName}...',
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ],
        ),
      ),
    );

    final bytes = await capturePng(repaintKey: repaintKey, pixelRatio: 3.0);
    if (!context.mounted) return;

    if (bytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppTheme.errorRed,
          content: Text('Failed to render card image. Please try again.'),
        ),
      );
      return;
    }

    final sanitizedName = card.fullName.replaceAll(RegExp(r'\s+'), '_');
    final filename = 'SmashDeck_${sanitizedName}_Card.png';

    // Trigger instant download on web
    if (kIsWeb) triggerFileDownload(bytes, filename);

    // Present high-res card export preview modal
    await showDialog(
      context: context,
      builder: (dialogContext) => CardExportPreviewDialog(
        card: card,
        pngBytes: bytes,
        filename: filename,
      ),
    );
  }
}

/// Dialog displaying the rendered card PNG with download & WhatsApp status sharing shortcuts
class CardExportPreviewDialog extends StatelessWidget {
  final TrumpCardModel card;
  final Uint8List pngBytes;
  final String filename;

  const CardExportPreviewDialog({
    super.key,
    required this.card,
    required this.pngBytes,
    required this.filename,
  });

  @override
  Widget build(BuildContext context) {
    final sizeKb = (pngBytes.lengthInBytes / 1024).toStringAsFixed(1);
    final tier = card.cardTier;

    return Dialog(
      backgroundColor: AppTheme.cardDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: tier.accentColor, width: 1.5),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Icon(Icons.verified, color: tier.accentColor, size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Your card is ready',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: tier.accentColor,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close,
                        color: Colors.white60, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Rendered Image Preview
              Center(
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 340),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: tier.glowColor,
                        blurRadius: 20,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.memory(
                      pngBytes,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Metadata chip row
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 6,
                runSpacing: 8,
                children: [
                  _buildMetaChip(
                    Icons.hd_outlined,
                    '3.0x Ultra-HD',
                    tier.accentColor,
                  ),
                  const SizedBox(width: 8),
                  _buildMetaChip(
                    Icons.data_usage,
                    '$sizeKb KB PNG',
                    Colors.white70,
                  ),
                  const SizedBox(width: 8),
                  _buildMetaChip(
                    Icons.star,
                    tier.displayName,
                    tier.accentColor,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              FilledButton.icon(
                icon: const Icon(Icons.ios_share),
                label: const Text('SHARE PNG'),
                onPressed: () => runClubAction(
                    context,
                    () => FileExportService.share(
                        pngBytes, filename, 'image/png')),
              ),
              const SizedBox(height: 10),
              Text(
                  'Choose WhatsApp, your gallery, or another app from the share menu.',
                  style: AppTheme.bodySm,
                  textAlign: TextAlign.center),
              if (kIsWeb)
                TextButton.icon(
                  icon: const Icon(Icons.download),
                  label: const Text('Download PNG'),
                  onPressed: () => triggerFileDownload(pngBytes, filename),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetaChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black45,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
