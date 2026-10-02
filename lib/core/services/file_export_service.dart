import 'dart:typed_data';
import 'package:share_plus/share_plus.dart';

class FileExportService {
  static Future<void> share(
      Uint8List bytes, String filename, String mimeType) async {
    await SharePlus.instance.share(ShareParams(
        files: [XFile.fromData(bytes, mimeType: mimeType, name: filename)],
        fileNameOverrides: [filename],
        title: filename));
  }
}
