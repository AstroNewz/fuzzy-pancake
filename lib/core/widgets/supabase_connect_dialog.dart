import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../network/supabase_service.dart';
import '../theme/app_theme.dart';

/// Interactive dialog for Supabase connection setup & offline mode
class SupabaseConnectDialog extends StatefulWidget {
  const SupabaseConnectDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) => const SupabaseConnectDialog(),
    );
  }

  @override
  State<SupabaseConnectDialog> createState() => _SupabaseConnectDialogState();
}

class _SupabaseConnectDialogState extends State<SupabaseConnectDialog> {
  late final TextEditingController _urlController;
  late final TextEditingController _keyController;
  bool _isLoading = false;
  String? _statusMessage;
  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: AppConstants.supabaseUrl);
    _keyController = TextEditingController(text: AppConstants.supabaseAnonKey);
  }

  @override
  void dispose() {
    _urlController.dispose();
    _keyController.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    setState(() {
      _isLoading = true;
      _statusMessage = null;
    });

    final url = _urlController.text.trim();
    final key = _keyController.text.trim();

    if (url.isEmpty || !url.startsWith('http')) {
      setState(() {
        _isLoading = false;
        _statusMessage =
            'Please enter a valid Supabase Project URL (https://xyz.supabase.co)';
        _isSuccess = false;
      });
      return;
    }

    try {
      await SupabaseService.initialize(url: url, anonKey: key);
      setState(() {
        _isLoading = false;
        _statusMessage = 'Connected successfully to Supabase!';
        _isSuccess = true;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Connection failed: ${e.toString().split('\n').first}';
        _isSuccess = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.cardDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppTheme.borderDark, width: 1),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3ECF8E).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.cloud_sync,
                    color: Color(0xFF3ECF8E),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Connect Supabase',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textWhite,
                        ),
                      ),
                      Text(
                        'Zero-cost cloud database & auth',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close,
                      color: AppTheme.textMuted, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Setup Instructions Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.cardDarker,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderDark),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Quick 3-Step Setup:',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryBright,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildStep('1', 'Create free project at supabase.com'),
                  _buildStep(
                      '2', 'Paste supabase/schema.sql into SQL Editor & run'),
                  _buildStep(
                      '3', 'Copy Project URL & anon key from Settings → API'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Form inputs
            const Text(
              'SUPABASE PROJECT URL',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppTheme.textMuted,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _urlController,
              style: const TextStyle(fontSize: 13, color: AppTheme.textWhite),
              decoration: InputDecoration(
                hintText: 'https://xyzproject.supabase.co',
                prefixIcon:
                    const Icon(Icons.link, size: 18, color: AppTheme.textMuted),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                filled: true,
                fillColor: AppTheme.cardDarker,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppTheme.borderDark),
                ),
              ),
            ),
            const SizedBox(height: 14),

            const Text(
              'ANON PUBLIC API KEY',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppTheme.textMuted,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _keyController,
              obscureText: true,
              style: const TextStyle(fontSize: 13, color: AppTheme.textWhite),
              decoration: InputDecoration(
                hintText: 'eyJhbGciOiJIUzI1NiIsInR5cCI6...',
                prefixIcon:
                    const Icon(Icons.key, size: 18, color: AppTheme.textMuted),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                filled: true,
                fillColor: AppTheme.cardDarker,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppTheme.borderDark),
                ),
              ),
            ),
            const SizedBox(height: 12),

            if (_statusMessage != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: _isSuccess
                      ? const Color(0x2210B981)
                      : const Color(0x22F43F5E),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _isSuccess
                        ? const Color(0xFF10B981)
                        : const Color(0xFFF43F5E),
                  ),
                ),
                child: Text(
                  _statusMessage!,
                  style: TextStyle(
                    fontSize: 12,
                    color: _isSuccess
                        ? const Color(0xFF10B981)
                        : const Color(0xFFF43F5E),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.textWhite,
                      side: const BorderSide(color: AppTheme.borderLight),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Running in Offline Squad Mode with 20 seeded players'),
                          backgroundColor: Color(0xFF131D18),
                        ),
                      );
                    },
                    child: const Text('Offline Mode',
                        style: TextStyle(fontSize: 13)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3ECF8E),
                      foregroundColor: const Color(0xFF0A122A),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: _isLoading ? null : _testConnection,
                    child: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text(
                            'Save & Connect',
                            style: TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w700),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 18,
            height: 18,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Color(0xFF283D33),
              shape: BoxShape.circle,
            ),
            child: Text(
              number,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryBright,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textWhite,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
