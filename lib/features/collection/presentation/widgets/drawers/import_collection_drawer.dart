import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:fluency/core/themes/app_colors_extension.dart';
import 'package:fluency/features/collection/data/repositories/collection_repository_impl.dart';
import 'package:fluency/core/services/monitoring/monitoring_service.dart';
import 'package:flutter/material.dart';

class ImportCollectionDrawer extends StatefulWidget {
  const ImportCollectionDrawer({
    required this.onImported,
    super.key,
  });

  final VoidCallback onImported;

  @override
  State<ImportCollectionDrawer> createState() => _ImportCollectionDrawerState();
}

class _ImportCollectionDrawerState extends State<ImportCollectionDrawer> {
  final _repository = CollectionRepositoryImpl();
  bool _isImporting = false;

  Future<void> _importFromCSV() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );

    if (result == null || result.files.single.path == null) {
      return;
    }

    setState(() => _isImporting = true);

    try {
      final file = File(result.files.single.path!);
      await _repository.importCollection(file);

      if (mounted) {
        Navigator.pop(context);
        widget.onImported();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Collection imported successfully!')),
        );
      }
    } catch (e, stack) {
      MonitoringService.captureError(e, stackTrace: stack);
      if (mounted) {
        setState(() => _isImporting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error importing: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;

    return Container(
      padding: const EdgeInsets.only(bottom: 28),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: appColors.drawerBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        border: Border.all(
          color: appColors.border.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          const SizedBox(height: 12),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: appColors.textSecondary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(height: 12),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Import Collection',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: appColors.textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Text(
                        'Choose an external source to import from',
                        style: TextStyle(
                          fontSize: 12,
                          color: appColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: appColors.inputBackground,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: appColors.border.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: appColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (_isImporting)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Column(
                children: [
                  _buildOption(
                    context,
                    icon: Icons.insert_drive_file_outlined,
                    title: 'From CSV File',
                    subtitle: 'Import collection from a CSV file',
                    onTap: _importFromCSV,
                    appColors: appColors,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    ),
                  ),
                  const SizedBox(height: 6),
                  _buildOption(
                    context,
                    icon: Icons.table_chart_outlined,
                    title: 'From Excel',
                    subtitle: 'Coming soon',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Excel import coming soon!')),
                      );
                    },
                    appColors: appColors,
                    isDisabled: true,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0EA5E9), Color(0xFF06B6D4)],
                    ),
                  ),
                  const SizedBox(height: 6),
                  _buildOption(
                    context,
                    icon: Icons.cloud_outlined,
                    title: 'From Google Sheets',
                    subtitle: 'Coming soon',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Google Sheets import coming soon!'),
                        ),
                      );
                    },
                    appColors: appColors,
                    isDisabled: true,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF10B981), Color(0xFF0EA5E9)],
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required AppColorsExtension appColors,
    required Gradient gradient,
    bool isDisabled = false,
  }) {
    return InkWell(
      onTap: isDisabled ? null : onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: appColors.cardBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: appColors.border.withValues(
              alpha: isDisabled ? 0.3 : 1.0,
            ),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: isDisabled
                    ? LinearGradient(
                        colors: [
                          Colors.grey.withValues(alpha: 0.5),
                          Colors.grey.withValues(alpha: 0.3),
                        ],
                      )
                    : gradient,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isDisabled
                          ? appColors.textSecondary.withValues(alpha: 0.5)
                          : appColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: appColors.textSecondary.withValues(
                        alpha: isDisabled ? 0.5 : 1.0,
                      ),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (!isDisabled)
              Icon(
                Icons.chevron_right_rounded,
                size: 16,
                color: appColors.textSecondary,
              ),
          ],
        ),
      ),
    );
  }
}
