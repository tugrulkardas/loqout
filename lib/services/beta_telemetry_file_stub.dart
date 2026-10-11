/// Web stub — no local filesystem for CSV temp files.
Future<String> writeBetaTelemetryCsvFile({
  required String csv,
  required String fileName,
}) async {
  throw UnsupportedError(
    'Temp-file CSV export is not available on web. Use a device build.',
  );
}
