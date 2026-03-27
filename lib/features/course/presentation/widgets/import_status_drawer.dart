import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fluency/core/themes/app_colors_extension.dart';
import 'package:fluency/core/constants/route_constants.dart';
import 'package:fluency/features/course/domain/entities/course.dart';
import 'package:fluency/features/course/data/course_repository.dart';

class ImportStatusDrawer extends StatefulWidget {
  const ImportStatusDrawer({
    required this.importAction,
    required this.onRetry,
    required this.appColors,
    super.key,
  });

  final Future<Course?> Function({
    bool force,
    void Function(double)? onProgress,
  }) importAction;
  final VoidCallback onRetry;
  final AppColorsExtension appColors;

  @override
  State<ImportStatusDrawer> createState() => _ImportStatusDrawerState();
}

class _ImportStatusDrawerState extends State<ImportStatusDrawer> {
  bool _isLoading = true;
  double _progress = 0;
  Course? _importedCourse;
  String? _error;
  CourseVersionConflictException? _conflict;

  @override
  void initState() {
    super.initState();
    _startImport();
  }

  Future<void> _startImport({bool force = false}) async {
    setState(() {
      _isLoading = true;
      _progress = 0;
      _error = null;
      _conflict = null;
    });

    try {
      final course = await widget.importAction(
        force: force,
        onProgress: (p) {
          if (mounted) {
            setState(() {
              _progress = p;
            });
          }
        },
      );
      if (mounted) {
        setState(() {
          _importedCourse = course;
          _isLoading = false;
        });
      }
    } on CourseVersionConflictException catch (e) {
      if (mounted) {
        setState(() {
          _conflict = e;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: widget.appColors.drawerBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: SafeArea(
        bottom: true,
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 0),
              width: 48,
              height: 6,
              decoration: BoxDecoration(
                color: widget.appColors.border.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(3),
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
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _isLoading
                              ? 'Importing Course...'
                              : (_conflict != null
                                  ? 'Version Conflict Detected'
                                  : (_error != null
                                      ? 'Import Failed'
                                      : 'Import Successful')),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: widget.appColors.textPrimary,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _isLoading
                              ? 'Please wait while we process the files'
                              : (_conflict != null
                                  ? 'A version of this course already exists'
                                  : (_error != null
                                      ? 'Something went wrong during import'
                                      : 'The course is now available in your library')),
                          style: TextStyle(
                            fontSize: 13,
                            color: widget.appColors.textSecondary,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!_isLoading)
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: widget.appColors.inputBackground,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color:
                                widget.appColors.border.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: widget.appColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Divider
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                height: 1,
                color: widget.appColors.divider.withValues(alpha: 0.1),
              ),
            ),
            const SizedBox(height: 12),
            // Content
            if (_isLoading)
              Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: _progress,
                        backgroundColor:
                            widget.appColors.primary.withValues(alpha: 0.1),
                        valueColor: AlwaysStoppedAnimation<Color>(
                            widget.appColors.primary),
                        minHeight: 12,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${(_progress * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: widget.appColors.primary,
                        fontFeatures: const [ui.FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              )
            else if (_conflict != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: widget.appColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: widget.appColors.primary
                                .withValues(alpha: 0.2)),
                      ),
                      child: Text(
                        _conflict!.type == CourseConflictType.older
                            ? 'You are importing an older version (v${_conflict!.newCourse.version}) while the current version is v${_conflict!.oldCourse.version}. Previous data may be overwritten if some lessons or cards were deleted in this package. Import anyway?'
                            : (_conflict!.type == CourseConflictType.same
                                ? 'This course already exists with the same version (v${_conflict!.oldCourse.version}).'
                                : 'An older version exists (v${_conflict!.oldCourse.version}). Would you like to update to the new version v${_conflict!.newCourse.version}? Existing data may be overwritten.'),
                        style: TextStyle(
                            color: widget.appColors.textPrimary, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildOption(
                      icon: Icons.check_circle_outline_rounded,
                      label: _conflict!.type == CourseConflictType.older
                          ? 'Import Anyway'
                          : 'Update Now',
                      description: 'Proceed with the import/update',
                      gradient: const LinearGradient(
                        colors: [Color(0xFF10B981), Color(0xFF3B82F6)],
                      ),
                      onTap: () => _startImport(force: true),
                    ),
                    const SizedBox(height: 12),
                    _buildOption(
                      icon: Icons.close_rounded,
                      label: 'Exit',
                      description: 'Cancel and go back',
                      gradient: LinearGradient(
                        colors: [
                          widget.appColors.textSecondary.withValues(alpha: 0.1),
                          widget.appColors.textSecondary.withValues(alpha: 0.2),
                        ],
                      ),
                      onTap: () => Navigator.pop(context),
                    ),
                  ],
                ),
              )
            else if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: Colors.red.withValues(alpha: 0.2)),
                      ),
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildOption(
                      icon: Icons.refresh_rounded,
                      label: 'Retry',
                      description: 'Try importing the file again',
                      gradient: const LinearGradient(
                        colors: [Color(0xFF3B82F6), Color(0xFF06B6D4)],
                      ),
                      onTap: widget.onRetry,
                    ),
                    const SizedBox(height: 12),
                    _buildOption(
                      icon: Icons.close_rounded,
                      label: 'Exit',
                      description: 'Close this dialog',
                      gradient: LinearGradient(
                        colors: [
                          widget.appColors.textSecondary.withValues(alpha: 0.1),
                          widget.appColors.textSecondary.withValues(alpha: 0.2),
                        ],
                      ),
                      onTap: () => Navigator.pop(context),
                    ),
                  ],
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    _buildOption(
                      icon: Icons.play_arrow_rounded,
                      label: 'Start Learning',
                      description: 'Start learning this course now',
                      gradient: const LinearGradient(
                        colors: [Color(0xFF10B981), Color(0xFF3B82F6)],
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        if (_importedCourse != null) {
                          context.push(
                            '${RouteConstants.course}/detail',
                            extra: _importedCourse,
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildOption(
                      icon: Icons.close_rounded,
                      label: 'Exit',
                      description: 'Go back to app',
                      gradient: LinearGradient(
                        colors: [
                          widget.appColors.textSecondary.withValues(alpha: 0.1),
                          widget.appColors.textSecondary.withValues(alpha: 0.2),
                        ],
                      ),
                      onTap: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildOption({
    required IconData icon,
    required String label,
    required String description,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: widget.appColors.cardBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: widget.appColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: gradient,
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
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: widget.appColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 11,
                      color: widget.appColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 16,
              color: widget.appColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
