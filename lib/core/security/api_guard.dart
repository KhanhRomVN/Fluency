import 'dart:convert';
import 'package:crypto/crypto.dart';

class ApiGuard {
  // Chuỗi bí mật chỉ Fluency app và Worker biết
  // Trong thực tế nên để ở C/C++ native layer hoặc obfuscate kỹ
  static const String _salt = "Fluency_Secret_2026_@Alpha";

  /// Tạo payload an toàn kèm theo timestamp và signature
  static Map<String, dynamic> securePayload(Map<String, dynamic> originalBody) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    // Thuật toán: SHA256(timestamp + "." + salt)
    // Đơn giản và hiệu quả. Có thể hash cả body nếu cần integrity cao hơn.
    // Nhưng để tránh vấn đề thứ tự key JSON, ta chỉ authenticate request source.
    final dataToHash = '$timestamp.$_salt';
    final bytes = utf8.encode(dataToHash);
    final digest = sha256.convert(bytes);
    final signature = digest.toString();

    return {
      ...originalBody,
      '_t': timestamp,
      '_s': signature,
    };
  }
}
