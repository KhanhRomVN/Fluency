import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:fluency/core/themes/app_colors_extension.dart';
import 'package:fluency/features/collection/data/repositories/collection_repository_impl.dart';
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
    } catch (e) {
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
      decoration: BoxDecoration(
        color: appColors.cardBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Import Collection',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: appColors.textPrimary,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_isImporting)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            )
          else ...[
            _buildOption(
              context,
              icon: Icons.insert_drive_file_outlined,
              title: 'From CSV File',
              subtitle: 'Import collection from a CSV file',
              onTap: _importFromCSV,
              appColors: appColors,
            ),
            const SizedBox(height: 12),
            _buildOption(
              context,
              icon: Icons.table_chart_outlined,
              title: 'From Excel',
              subtitle: 'Coming soon',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Excel import coming soon!')),
                );
              },
              appColors: appColors,
              isDisabled: true,
            ),
            const SizedBox(height: 12),
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
            ),
          ],
          const SizedBox(height: 20),
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
    bool isDisabled = false,
  }) {
    return InkWell(
      onTap: isDisabled ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isDisabled
                ? appColors.border.withValues(alpha: 0.3)
                : appColors.border,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isDisabled
                  ? appColors.textSecondary.withValues(alpha: 0.3)
                  : appColors.primary,
              size: 28,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDisabled
                          ? appColors.textSecondary.withValues(alpha: 0.5)
                          : appColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: appColors.textSecondary.withValues(
                        alpha: isDisabled ? 0.5 : 1.0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (!isDisabled)
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: appColors.textSecondary,
              ),
          ],
        ),
      ),
    );
  }
}
