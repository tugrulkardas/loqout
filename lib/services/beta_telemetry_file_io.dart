import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Writes [csv] into the temp directory; returns the absolute file path.
Future<String> writeBetaTelemetryCsvFile({
  required String csv,
  required String fileName,
}) async {
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}${Platform.pathSeparator}$fileName');
  await file.writeAsString(csv, flush: true);
  return file.path;
}
