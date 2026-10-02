import 'dart:typed_data';

/// Stub implementation for non-web environments (tests, VM, desktop)
void triggerFileDownload(Uint8List bytes, String filename) {
  // In native/VM, this is handled via platform sharing or file saving
}
