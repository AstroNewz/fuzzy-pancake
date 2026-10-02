import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/data/mock_squad_data.dart';
import '../../core/theme/app_theme.dart';
import '../auth/auth_state.dart';
import 'attendance_repository.dart';

/// Modal In-App QR Scanner Sheet with Viewfinder & Manual Input Option
class AttendanceScannerSheet extends ConsumerStatefulWidget {
  const AttendanceScannerSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AttendanceScannerSheet(),
    );
  }

  @override
  ConsumerState<AttendanceScannerSheet> createState() =>
      _AttendanceScannerSheetState();
}

class _AttendanceScannerSheetState
    extends ConsumerState<AttendanceScannerSheet> {
  late MobileScannerController _scannerController;
  bool _isProcessing = false;
  bool _isTorchOn = false;

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _handleBarcodeDetected(String rawPayload) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    final currentUser = ref.read(currentPlayerProfileProvider).value;
    // Default to first squad member if guest/admin testing
    final playerId = currentUser?.id ?? MockSquadData.players.first.id;
    final playerName =
        currentUser?.fullName ?? MockSquadData.players.first.fullName;

    final repo = ref.read(attendanceRepositoryProvider);
    final result = await repo.processQrCheckIn(
      playerId: playerId,
      qrPayload: rawPayload,
    );

    if (!mounted) return;

    if (result.isSuccess) {
      // Invalidate attendance providers to refresh list
      ref.invalidate(todayAttendanceRecordsProvider);

      Navigator.pop(context); // Close scanner sheet
      _showSuccessDialog(playerName, result);
    } else {
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppTheme.errorRed,
          behavior: SnackBarBehavior.floating,
          content: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text(result.message)),
            ],
          ),
        ),
      );
    }
  }

  void _showManualInputDialog() {
    final textController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.keyboard, color: AppTheme.primaryNeon),
            SizedBox(width: 10),
            Text('Manual Code Entry'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter the 6-digit TOTP from the Admin Screen or full payload string:',
              style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: textController,
              autofocus: true,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                letterSpacing: 2.0,
              ),
              decoration: InputDecoration(
                hintText: 'e.g. 582914 or SMASHDECK:...',
                hintStyle:
                    const TextStyle(color: Colors.white24, letterSpacing: 1.0),
                filled: true,
                fillColor: Colors.black26,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.borderDark),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.primaryNeon),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL',
                style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              final raw = textController.text.trim();
              Navigator.pop(ctx);
              if (raw.isNotEmpty) {
                // If user entered only 6 digits, construct standard payload
                final now = DateTime.now();
                final dateStr =
                    '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
                final fullPayload = raw.startsWith('SMASHDECK:')
                    ? raw
                    : 'SMASHDECK:$dateStr:$raw';
                _handleBarcodeDetected(fullPayload);
              }
            },
            child: const Text('SUBMIT'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String playerName, CheckInResult result) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryNeon.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check,
                  color: AppTheme.primaryNeon, size: 24),
            ),
            const SizedBox(width: 12),
            const Text(
              'Attendance Marked!',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              playerName,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              result.message,
              style: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black38,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color:
                      result.isOffline ? Colors.orange : AppTheme.primaryNeon,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    result.isOffline ? Icons.cloud_off : Icons.verified,
                    color:
                        result.isOffline ? Colors.orange : AppTheme.primaryNeon,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      result.isOffline
                          ? 'Saved to Local Cache (Offline)'
                          : 'Official Session Token Logged in Supabase',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: result.isOffline ? Colors.orange : Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('GREAT'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: AppTheme.bgDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Drag Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Scan Session QR',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Point camera at Admin screen QR code',
                      style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                    ),
                  ],
                ),
                Row(
                  children: [
                    // Flash Toggle
                    IconButton(
                      icon: Icon(
                        _isTorchOn ? Icons.flash_on : Icons.flash_off,
                        color: _isTorchOn ? Colors.amber : Colors.white70,
                      ),
                      onPressed: () async {
                        await _scannerController.toggleTorch();
                        setState(() => _isTorchOn = !_isTorchOn);
                      },
                    ),
                    // Camera Switch
                    IconButton(
                      icon:
                          const Icon(Icons.cameraswitch, color: Colors.white70),
                      onPressed: () => _scannerController.switchCamera(),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Camera Viewport with Viewfinder Overlay
          Expanded(
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: MobileScanner(
                    controller: _scannerController,
                    onDetect: (capture) {
                      final barcodes = capture.barcodes;
                      for (final barcode in barcodes) {
                        final raw = barcode.rawValue;
                        if (raw != null && raw.isNotEmpty) {
                          _handleBarcodeDetected(raw);
                          break;
                        }
                      }
                    },
                  ),
                ),

                // Viewfinder Frame & Corner Highlights
                Center(
                  child: Container(
                    width: 240,
                    height: 240,
                    decoration: BoxDecoration(
                      border:
                          Border.all(color: AppTheme.primaryNeon, width: 2.5),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryNeon.withValues(alpha: 0.25),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        // Animated Scanning Indicator Line
                        if (!_isProcessing)
                          const Center(
                            child: Divider(
                              color: AppTheme.primaryNeon,
                              thickness: 2,
                            ),
                          ),
                        if (_isProcessing)
                          const Center(
                            child: CircularProgressIndicator(
                              color: AppTheme.primaryNeon,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // Instruction Label
                Positioned(
                  bottom: 24,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Align QR Code within the green frame',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Fallback Manual Code Entry Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: AppTheme.borderDark),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: const Icon(Icons.keyboard, size: 18),
                    label: const Text(
                      'TYPE TOKEN MANUALLY',
                      style:
                          TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                    onPressed: _showManualInputDialog,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
