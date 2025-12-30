// Stub file for web platform - replaces dart:io
// This file is only used when compiling for web

class Directory {
  final String path;
  Directory(this.path);
  Future<bool> exists() async => false;
  Future<Directory> create({bool recursive = false}) async => this;
}

class File {
  final String path;
  File(this.path);
  Future<bool> exists() async => false;
  Future<String> readAsString() async => '';
  Future<File> writeAsString(String contents) async => this;
}
