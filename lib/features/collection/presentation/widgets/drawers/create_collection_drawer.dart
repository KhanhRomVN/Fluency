import 'package:fluency/core/services/monitoring/monitoring_service.dart';
import 'package:fluency/core/themes/app_colors_extension.dart';
import 'package:fluency/features/collection/data/repositories/collection_repository_impl.dart';
import 'package:flutter/material.dart';

class CreateCollectionDrawer extends StatefulWidget {
  const CreateCollectionDrawer({
    required this.onCreated,
    super.key,
  });

  final VoidCallback onCreated;

  @override
  State<CreateCollectionDrawer> createState() => _CreateCollectionDrawerState();
}

class _CreateCollectionDrawerState extends State<CreateCollectionDrawer> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _repository = CollectionRepositoryImpl();
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_updateButtonState);
    _descriptionController.addListener(_updateButtonState);
  }

  void _updateButtonState() {
    setState(() {});
  }

  @override
  void dispose() {
    _nameController.removeListener(_updateButtonState);
    _descriptionController.removeListener(_updateButtonState);
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  bool get _isValid {
    final name = _nameController.text.trim();
    final desc = _descriptionController.text.trim();
    return name.length >= 10 &&
        name.length <= 30 &&
        desc.length >= 25 &&
        desc.length <= 100;
  }

  Future<void> _createCollection() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim();

    setState(() => _isCreating = true);

    try {
      await _repository.createCollection(
        name,
        description,
      );

      if (mounted) {
        Navigator.pop(context);
        widget.onCreated();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Collection "$name" created!')),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e, stack) {
      MonitoringService.captureError(e, stackTrace: stack);
      if (mounted) {
        setState(() => _isCreating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: appColors.drawerBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 40,
              offset: const Offset(0, -10),
            ),
          ],
        ),
        child: Column(
          children: [
            // Drag Handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: appColors.textSecondary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Create Collection',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: appColors.textPrimary,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Text(
                          'Create a group to organize your vocabulary',
                          style: TextStyle(
                            fontSize: 12,
                            color: appColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(10),
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
            const SizedBox(height: 4),
            // Form Content
            Expanded(
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListenableBuilder(
                        listenable: _nameController,
                        builder: (context, _) => _buildFieldLabel(
                          appColors,
                          'Name',
                          isRequired: true,
                          currentLength: _nameController.text.length,
                          maxLength: 30,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _nameController,
                        style: TextStyle(color: appColors.textPrimary),
                        maxLength: 30,
                        decoration: _buildInputDecoration(
                          appColors,
                          hintText: 'e.g., IELTS Vocabulary 2024',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a name';
                          }
                          if (value.trim().length < 10) {
                            return 'Name must be at least 10 characters';
                          }
                          return null;
                        },
                        enabled: !_isCreating,
                      ),
                      const SizedBox(height: 16),
                      ListenableBuilder(
                        listenable: _descriptionController,
                        builder: (context, _) => _buildFieldLabel(
                          appColors,
                          'Description',
                          isRequired: true,
                          currentLength: _descriptionController.text.length,
                          maxLength: 100,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _descriptionController,
                        style: TextStyle(color: appColors.textPrimary),
                        minLines: 3,
                        maxLines: 5,
                        maxLength: 100,
                        decoration: _buildInputDecoration(
                          appColors,
                          hintText:
                              'Describe the purpose of this collection...',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a description';
                          }
                          if (value.trim().length < 25) {
                            return 'Description must be at least 25 characters';
                          }
                          return null;
                        },
                        enabled: !_isCreating,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Action Button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: SizedBox(
                width: double.infinity,
                height: 42,
                child: ElevatedButton(
                  onPressed:
                      (_isCreating || !_isValid) ? null : _createCollection,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: (_isCreating || !_isValid)
                        ? Colors.grey.withValues(alpha: 0.1)
                        : appColors.primary.withValues(alpha: 0.1),
                    foregroundColor: (_isCreating || !_isValid)
                        ? appColors.textSecondary.withValues(alpha: 0.5)
                        : appColors.primary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isCreating
                      ? SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                appColors.textSecondary.withValues(alpha: 0.5)),
                          ),
                        )
                      : const Text(
                          'Create',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldLabel(
    AppColorsExtension appColors,
    String label, {
    bool isRequired = false,
    int? currentLength,
    int? maxLength,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: appColors.textPrimary.withValues(alpha: 0.8),
              ),
            ),
            if (isRequired)
              Text(
                ' *',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade400,
                ),
              ),
          ],
        ),
        if (currentLength != null && maxLength != null)
          Text(
            '$currentLength/$maxLength',
            style: TextStyle(
              fontSize: 11,
              color: appColors.textSecondary.withValues(alpha: 0.6),
            ),
          ),
      ],
    );
  }

  InputDecoration _buildInputDecoration(
    AppColorsExtension appColors, {
    required String hintText,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(
        color: appColors.textSecondary.withValues(alpha: 0.5),
        fontSize: 14,
      ),
      filled: true,
      fillColor: appColors.inputBackground,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      counterText: '',
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
            color: appColors.border.withValues(alpha: 0.3), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: appColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red.shade400, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red.shade400, width: 1.5),
      ),
      errorStyle: TextStyle(color: Colors.red.shade400, fontSize: 12),
    );
  }
}
