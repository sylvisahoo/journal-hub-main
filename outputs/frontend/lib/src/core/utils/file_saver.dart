import 'web_downloader_stub.dart' if (dart.library.html) 'web_downloader.dart';

void saveBackupFile(String content, String fileName) {
  downloadFileWeb(content, fileName);
}
