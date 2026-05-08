import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

class OfflineGalleryService {
  static final _dio = Dio();

  /// Download a photo to local storage. Returns local file path.
  static Future<String?> downloadPhoto(String url, String filename) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final galleryDir = Directory('${dir.path}/kamotohd_gallery');
      if (!await galleryDir.exists()) await galleryDir.create(recursive: true);

      final localPath = '${galleryDir.path}/$filename';
      if (await File(localPath).exists()) return localPath; // already cached

      await _dio.download(url, localPath);
      return localPath;
    } catch (_) {
      return null;
    }
  }

  /// Check if a photo is already downloaded.
  static Future<bool> isDownloaded(String filename) async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/kamotohd_gallery/$filename').exists();
  }

  /// Get local file if downloaded, null otherwise.
  static Future<File?> getLocalFile(String filename) async {
    final dir = await getApplicationDocumentsDirectory();
    final f = File('${dir.path}/kamotohd_gallery/$filename');
    return await f.exists() ? f : null;
  }
}
