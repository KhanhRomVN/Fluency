import 'dart:io';

bool fileExists(String path) {
  return File(path).existsSync();
}

bool directoryExists(String path) {
  return Directory(path).existsSync();
}
