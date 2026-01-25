import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:fluency/features/course/presentation/providers/course_provider.dart';
import 'package:fluency/features/setting/presentation/pages/about_page.dart';
import 'package:fluency/features/setting/presentation/pages/faq_page.dart';
import 'package:fluency/features/setting/presentation/pages/reminder_page.dart';
import 'package:fluency/features/setting/presentation/widgets/setting_section_header.dart';
import 'package:fluency/features/setting/presentation/widgets/setting_tile.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingPage extends StatelessWidget {
  const SettingPage({super.key});

  Future<void> _importCourse(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip'],
      );

      if (result != null && result.files.single.path != null) {
        final path = result.files.single.path!;

        // Show loading indicator
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đang nhập khóa học...')),
          );
        }

        if (!context.mounted) return;

        await Provider.of<CourseProvider>(context, listen: false)
            .importCourse(path);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Nhập khóa học thành công!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Nhập khóa học thất bại: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _exportData(BuildContext context) async {
    try {
      // Show loading
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đang xuất dữ liệu...')),
        );
      }

      // TODO(user): Implement actual data export
      await Future<void>.delayed(const Duration(seconds: 1));

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Xuất dữ liệu thành công!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Xuất dữ liệu thất bại: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _contactSupport() async {
    final emailUri = Uri(
      scheme: 'mailto',
      path: 'support@fluency.app',
      query:
          'subject=Hỗ trợ ứng dụng Fluency&body=Xin chào, tôi cần hỗ trợ về...',
    );

    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    }
  }

  Future<void> _rateApp(BuildContext context) async {
    // For mobile platforms
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      final String storeUrl;
      if (Platform.isAndroid) {
        storeUrl =
            'https://play.google.com/store/apps/details?id=com.fluency.app';
      } else {
        storeUrl = 'https://apps.apple.com/app/fluency/id123456789';
      }

      final uri = Uri.parse(storeUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } else {
      // For web or other platforms
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cảm ơn bạn đã sử dụng Fluency!'),
          ),
        );
      }
    }
  }

  Future<void> _shareApp(BuildContext context) async {
    try {
      await Share.share(
        'Học tiếng Anh cùng Fluency! Tải ngay: https://fluency.app',
        subject: 'Ứng dụng học tiếng Anh Fluency',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể chia sẻ: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cài đặt'),
        centerTitle: false,
      ),
      body: ListView(
        children: [
          // Learning Section
          const SettingSectionHeader(title: 'Học tập'),
          SettingTile(
            icon: Icons.notifications_active,
            iconColor: Colors.orange,
            title: 'Nhắc nhở học tập',
            subtitle: 'Cài đặt thông báo nhắc nhở hàng ngày',
            onTap: () {
              Navigator.push<void>(
                context,
                MaterialPageRoute<void>(
                  builder: (context) => const ReminderPage(),
                ),
              );
            },
          ),

          // Data Section
          const SettingSectionHeader(title: 'Dữ liệu'),
          SettingTile(
            icon: Icons.file_download,
            iconColor: Colors.blue,
            title: 'Nhập khóa học',
            subtitle: 'Nhập khóa học từ file .zip',
            onTap: () => _importCourse(context),
          ),
          SettingTile(
            icon: Icons.file_upload,
            iconColor: Colors.teal,
            title: 'Xuất dữ liệu',
            subtitle: 'Sao lưu tiến độ và cài đặt của bạn',
            onTap: () => _exportData(context),
          ),

          // Support Section
          const SettingSectionHeader(title: 'Hỗ trợ'),
          SettingTile(
            icon: Icons.help,
            iconColor: Colors.purple,
            title: 'FAQ',
            subtitle: 'Câu hỏi thường gặp',
            onTap: () {
              Navigator.push<void>(
                context,
                MaterialPageRoute<void>(
                  builder: (context) => const FaqPage(),
                ),
              );
            },
          ),
          SettingTile(
            icon: Icons.support_agent,
            iconColor: Colors.pink,
            title: 'Liên hệ hỗ trợ',
            subtitle: 'Gửi email cho đội ngũ hỗ trợ',
            onTap: _contactSupport,
          ),

          // App Section
          const SettingSectionHeader(title: 'Ứng dụng'),
          SettingTile(
            icon: Icons.star,
            iconColor: Colors.amber,
            title: 'Đánh giá ứng dụng',
            subtitle: 'Đánh giá trên App Store / Google Play',
            onTap: () => _rateApp(context),
          ),
          SettingTile(
            icon: Icons.share,
            iconColor: Colors.green,
            title: 'Chia sẻ ứng dụng',
            subtitle: 'Giới thiệu Fluency với bạn bè',
            onTap: () => _shareApp(context),
          ),
          SettingTile(
            icon: Icons.info,
            iconColor: Colors.indigo,
            title: 'Về ứng dụng',
            subtitle: 'Thông tin phiên bản và giấy phép',
            onTap: () {
              Navigator.push<void>(
                context,
                MaterialPageRoute<void>(
                  builder: (context) => const AboutPage(),
                ),
              );
            },
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
