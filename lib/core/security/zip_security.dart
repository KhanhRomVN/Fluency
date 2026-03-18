import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:crypto/crypto.dart';
import 'package:fluency/core/security/zip_password_calc.dart';
import 'package:flutter/foundation.dart';

class ZipSecurity {
  // Obfuscated password components moved to ZipPasswordCalc

  static const _storage = FlutterSecureStorage();
  static const String _storageKeyEncryptionKey = 'storage_encryption_key';
  static const String _storageKeyZipPassword = 'zip_decryption_password';

  static String? _cachedZipPassword;
  static encrypt.Key? _cachedEncryptionKey;

  /// Khởi tạo và lấy mật khẩu ZIP từ Secure Storage
  static Future<String> getZipPassword() async {
    if (_cachedZipPassword != null) return _cachedZipPassword!;

    try {
      String? pwd = await _storage.read(key: _storageKeyZipPassword);
      if (pwd == null) {
        pwd = ZipPasswordCalc.getDefaultPassword();
        await _storage.write(key: _storageKeyZipPassword, value: pwd);
      }
      _cachedZipPassword = pwd;
      return pwd;
    } catch (e) {
      debugPrint(
          'Warning: Secure Storage unavailable for password, using default obfuscated password. Error: $e');
      final pwd = ZipPasswordCalc.getDefaultPassword();
      _cachedZipPassword = pwd;
      return pwd;
    }
  }

  /// Khởi tạo và lấy khóa mã hóa cho Storage
  static Future<encrypt.Key> getEncryptionKey() async {
    if (_cachedEncryptionKey != null) return _cachedEncryptionKey!;

    try {
      String? keyStr = await _storage.read(key: _storageKeyEncryptionKey);
      if (keyStr == null) {
        // Tạo khóa mới nếu chưa có
        final newKey = encrypt.Key.fromSecureRandom(32);
        keyStr = base64Encode(newKey.bytes);
        await _storage.write(key: _storageKeyEncryptionKey, value: keyStr);
      }
      final key = encrypt.Key.fromBase64(keyStr);
      _cachedEncryptionKey = key;
      return key;
    } catch (e) {
      debugPrint(
          'Warning: Secure Storage unavailable for key, using session-based fixed key. Error: $e');
      // For fallback when plugin fails, we use a key derived from the password to maintain some consistency
      final bytes = sha256
          .convert(utf8.encode(ZipPasswordCalc.getDefaultPassword()))
          .bytes;
      final key = encrypt.Key(Uint8List.fromList(bytes));
      _cachedEncryptionKey = key;
      return key;
    }
  }

  /// Lấy khóa mã hóa cho Hive (32-byte List<int>)
  static Future<List<int>> getHiveEncryptionKey() async {
    final key = await getEncryptionKey();
    return key.bytes;
  }

  /// Tính toán SHA-256 Checksum của một file
  static Future<String> calculateChecksum(List<int> bytes) async {
    return sha256.convert(bytes).toString();
  }
}
