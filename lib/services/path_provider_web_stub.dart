// Stub file for web platform
// This file is used when compiling for web to avoid path_provider import errors

/// Stub for getApplicationDocumentsDirectory - never called on web
Future<dynamic> getApplicationDocumentsDirectory() async {
  throw UnsupportedError('getApplicationDocumentsDirectory is not available on web platform');
}
