import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:isolate';
import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt_pkg;

/// Top-level function for asset extraction (to be used with Isolate.spawn)
void extractZipBytesIsolate(Map<String, dynamic> params) {
  final bytes = params['bytes'] as Uint8List;
  final extractPath = params['extractPath'] as String;
  final zipPassword = params['zipPassword'] as String;
  final encryptionKeyStr = params['encryptionKey'] as String?;
  final sendPort = params['sendPort'] as SendPort?;

  final encryptionKey = encryptionKeyStr != null
      ? encrypt_pkg.Key.fromBase64(encryptionKeyStr)
      : null;
  // Use a fixed IV for internal cache encryption to ensure consistency
  final iv = encrypt_pkg.IV(Uint8List(16));
  final encrypter = encryptionKey != null
      ? encrypt_pkg.Encrypter(encrypt_pkg.AES(encryptionKey))
      : null;

  try {
    final archive = ZipDecoder().decodeBytes(bytes, password: zipPassword);
    final totalFiles = archive.length;
    int processedFiles = 0;

    // Checksum verification if checksum.txt exists
    ArchiveFile? checksumFile;
    for (final file in archive) {
      if (file.name == 'checksum.txt') {
        checksumFile = file;
        break;
      }
    }

    for (final file in archive) {
      final filename = file.name;
      processedFiles++;

      // Send progress update
      if (sendPort != null && totalFiles > 0) {
        sendPort.send(processedFiles / totalFiles);
      }

      if (filename == 'checksum.txt') continue;

      final fullPath = '$extractPath/$filename';
      if (file.isFile) {
        if (filename.startsWith('__MACOSX') || filename.contains('.DS_Store'))
          continue;

        var data = file.content as List<int>;

        // Checksum validation for JSON files
        if (checksumFile != null && filename.endsWith('.json')) {
          final expectedChecksums =
              utf8.decode(checksumFile.content as List<int>);
          final currentChecksum = sha256.convert(data).toString();

          if (expectedChecksums.contains(currentChecksum)) {
            // Valid
          } else if (expectedChecksums.trim().isNotEmpty) {
            // If the list exists but doesn't contain this hash
            if (filename.toLowerCase().contains('course') ||
                filename.toLowerCase().contains('lesson')) {
              throw Exception(
                  'Security Error: Checksum mismatch for essential file $filename. Data might be tampered.');
            } else {
              print(
                  'Warning: Checksum mismatch or missing for $filename. Continuing anyway as it is non-essential.');
            }
          }
        }

        final outputFile = File(fullPath);
        outputFile.parent.createSync(recursive: true);

        // Encryption for JSON files
        if (encrypter != null && filename.endsWith('.json')) {
          final encrypted = encrypter.encrypt(utf8.decode(data), iv: iv);
          outputFile.writeAsBytesSync(encrypted.bytes);
        } else {
          outputFile.writeAsBytesSync(data);
        }
      } else {
        Directory(fullPath).createSync(recursive: true);
      }
    }

    // Final progress
    if (sendPort != null) {
      sendPort.send(1.0);
    }
  } catch (e) {
    if (sendPort != null) {
      sendPort.send('error: $e');
    }
  }
}

/// Top-level function for file extraction (to be used with Isolate.spawn)
void extractZipPathIsolate(Map<String, dynamic> params) {
  final zipPath = params['zipPath'] as String;
  final extractPath = params['extractPath'] as String;
  final zipPassword = params['zipPassword'] as String;
  final encryptionKeyStr = params['encryptionKey'] as String?;
  final sendPort = params['sendPort'] as SendPort?;

  final encryptionKey = encryptionKeyStr != null
      ? encrypt_pkg.Key.fromBase64(encryptionKeyStr)
      : null;
  // Use a fixed IV for internal cache encryption to ensure consistency
  final iv = encrypt_pkg.IV(Uint8List(16));
  final encrypter = encryptionKey != null
      ? encrypt_pkg.Encrypter(encrypt_pkg.AES(encryptionKey))
      : null;

  try {
    final bytes = File(zipPath).readAsBytesSync();
    final archive = ZipDecoder().decodeBytes(bytes, password: zipPassword);
    final totalFiles = archive.length;
    int processedFiles = 0;

    // Checksum verification if checksum.txt exists
    ArchiveFile? checksumFile;
    for (final file in archive) {
      if (file.name == 'checksum.txt') {
        checksumFile = file;
        break;
      }
    }

    for (final file in archive) {
      final filename = file.name;
      processedFiles++;

      // Send progress update
      if (sendPort != null && totalFiles > 0) {
        sendPort.send(processedFiles / totalFiles);
      }

      if (filename == 'checksum.txt') continue;

      final fullPath = '$extractPath/$filename';
      if (file.isFile) {
        if (filename.startsWith('__MACOSX') || filename.contains('.DS_Store'))
          continue;

        var data = file.content as List<int>;

        // Checksum validation for JSON files
        if (checksumFile != null && filename.endsWith('.json')) {
          final expectedChecksums =
              utf8.decode(checksumFile.content as List<int>);
          final currentChecksum = sha256.convert(data).toString();

          if (expectedChecksums.contains(currentChecksum)) {
            // Valid
          } else if (expectedChecksums.trim().isNotEmpty) {
            if (filename.toLowerCase().contains('course') ||
                filename.toLowerCase().contains('lesson')) {
              throw Exception(
                  'Security Error: Checksum mismatch for essential file $filename. Data might be tampered.');
            } else {
              print(
                  'Warning: Checksum mismatch or missing for $filename. Continuing anyway as it is non-essential.');
            }
          }
        }

        final outputFile = File(fullPath);
        outputFile.parent.createSync(recursive: true);

        // Encryption for JSON files
        if (encrypter != null && filename.endsWith('.json')) {
          final encrypted = encrypter.encrypt(utf8.decode(data), iv: iv);
          outputFile.writeAsBytesSync(encrypted.bytes);
        } else {
          outputFile.writeAsBytesSync(data);
        }
      } else {
        Directory(fullPath).createSync(recursive: true);
      }
    }

    // Final progress
    if (sendPort != null) {
      sendPort.send(1.0);
    }
  } catch (e) {
    if (sendPort != null) {
      sendPort.send('error: $e');
    }
  }
}
