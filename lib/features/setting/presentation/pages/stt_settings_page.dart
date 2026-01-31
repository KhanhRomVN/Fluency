import 'package:fluency/core/themes/app_colors_extension.dart';
import 'package:fluency/features/setting/domain/entities/stt_provider_type.dart';
import 'package:fluency/features/setting/domain/entities/vosk_model.dart';
import 'package:fluency/features/setting/data/services/vosk_model_manager.dart';
import 'package:fluency/features/setting/presentation/providers/stt_setting_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SttSettingsPage extends StatefulWidget {
  const SttSettingsPage({super.key});

  @override
  State<SttSettingsPage> createState() => _SttSettingsPageState();
}

class _SttSettingsPageState extends State<SttSettingsPage> {
  final VoskModelManager _modelManager = VoskModelManager();
  final Map<String, ModelDownloadProgress> _downloadProgress = {};
  final Map<String, bool> _modelDownloaded = {};

  @override
  void initState() {
    super.initState();
    _checkModelsStatus();
  }

  @override
  void dispose() {
    _modelManager.dispose();
    super.dispose();
  }

  Future<void> _checkModelsStatus() async {
    for (final model in VoskModel.availableModels) {
      final isDownloaded = await _modelManager.isModelDownloaded(model);
      if (mounted) {
        setState(() {
          _modelDownloaded[model.id] = isDownloaded;
        });
      }
    }
  }

  Future<void> _downloadModel(VoskModel model) async {
    setState(() {
      _downloadProgress[model.id] = ModelDownloadProgress(
        modelId: model.id,
        status: ModelDownloadStatus.downloading,
        progress: 0.0,
      );
    });

    try {
      await _modelManager.downloadModel(model, (progress) {
        if (mounted) {
          setState(() {
            _downloadProgress[model.id] = progress;
          });

          if (progress.status == ModelDownloadStatus.downloaded) {
            _modelDownloaded[model.id] = true;
            _downloadProgress.remove(model.id);

            // Auto-select this model if no model is selected yet
            final sttProvider = context.read<SttSettingProvider>();
            if (sttProvider.selectedModelId == null) {
              sttProvider.setSelectedModel(model.id);
            }

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${model.name} downloaded successfully!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to download ${model.name}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteModel(VoskModel model) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Model'),
        content: Text('Are you sure you want to delete ${model.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _modelManager.deleteModel(model);
      if (mounted) {
        setState(() {
          _modelDownloaded[model.id] = false;
          _downloadProgress.remove(model.id);
        });
      }
    }
  }

  Future<void> _cancelDownload(VoskModel model) async {
    await _modelManager.cancelDownload(model);
    if (mounted) {
      setState(() {
        _downloadProgress.remove(model.id);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorsExtension>();
    final primaryColor = colors?.primary ?? Theme.of(context).primaryColor;
    final sttProvider = context.watch<SttSettingProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Speech-to-Text Settings'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(context, 'Service Provider'),
            const SizedBox(height: 8),
            ...SttProviderType.values.map((type) => _buildProviderTile(
                  context,
                  type,
                  sttProvider.currentProviderType == type,
                  sttProvider,
                )),
            const SizedBox(height: 32),
            if (sttProvider.currentProviderType == SttProviderType.vosk) ...[
              _buildSectionHeader(context, 'Offline Models'),
              const SizedBox(height: 12),
              _buildWarningCard(context),
              const SizedBox(height: 12),
              ...VoskModel.availableModels.map((model) => _buildModelTile(
                    context,
                    model,
                    isDownloaded: _modelDownloaded[model.id] ?? false,
                    progress: _downloadProgress[model.id],
                    onDownload: () => _downloadModel(model),
                    onDelete: () => _deleteModel(model),
                    onCancel: () => _cancelDownload(model),
                  )),
            ],
            const SizedBox(height: 32),
            _buildInfoCard(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final colors = Theme.of(context).extension<AppColorsExtension>();
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: colors?.textSecondary.withOpacity(0.7),
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildProviderTile(
    BuildContext context,
    SttProviderType type,
    bool isSelected,
    SttSettingProvider provider,
  ) {
    final colors = Theme.of(context).extension<AppColorsExtension>();
    final primaryColor = colors?.primary ?? Theme.of(context).primaryColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isSelected
            ? primaryColor.withOpacity(0.05)
            : colors?.cardBackground.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected
              ? primaryColor
              : colors?.divider.withOpacity(0.1) ?? Colors.transparent,
          width: 1.5,
        ),
      ),
      child: RadioListTile<SttProviderType>(
        value: type,
        groupValue: provider.currentProviderType,
        onChanged: (value) {
          if (value != null) provider.setProviderType(value);
        },
        activeColor: primaryColor,
        title: Text(
          type.label,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          type.description,
          style: TextStyle(color: colors?.textSecondary, fontSize: 13),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _buildModelTile(
    BuildContext context,
    VoskModel model, {
    required bool isDownloaded,
    required ModelDownloadProgress? progress,
    required VoidCallback onDownload,
    required VoidCallback onDelete,
    required VoidCallback onCancel,
  }) {
    final colors = Theme.of(context).extension<AppColorsExtension>();
    final primaryColor = colors?.primary ?? Theme.of(context).primaryColor;
    final isDownloading = progress?.status == ModelDownloadStatus.downloading;
    final sttProvider = context.watch<SttSettingProvider>();
    final isSelected = sttProvider.selectedModelId == model.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors?.cardBackground.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: isDownloaded && isSelected
            ? Border.all(color: primaryColor, width: 2)
            : null,
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Radio button for downloaded models
              if (isDownloaded)
                Radio<String>(
                  value: model.id,
                  groupValue: sttProvider.selectedModelId,
                  onChanged: (value) {
                    if (value != null) {
                      sttProvider.setSelectedModel(value);
                    }
                  },
                  activeColor: primaryColor,
                )
              else
                const SizedBox(width: 48), // Placeholder for alignment
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.language, color: primaryColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          model.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        if (isDownloaded && isSelected) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'ACTIVE',
                              style: TextStyle(
                                color: primaryColor,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      model.description,
                      style:
                          TextStyle(color: colors?.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
              if (isDownloaded)
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: onDelete,
                )
              else if (isDownloading)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: onCancel,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      iconSize: 20,
                    ),
                  ],
                )
              else
                IconButton(
                  icon: Icon(Icons.download_for_offline, color: primaryColor),
                  onPressed: onDownload,
                ),
            ],
          ),
          if (isDownloading && progress != null) ...[
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: progress.progress,
              backgroundColor: colors?.divider.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
            ),
            const SizedBox(height: 4),
            Text(
              '${(progress.progress * 100).toStringAsFixed(0)}%',
              style: TextStyle(
                fontSize: 12,
                color: colors?.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorsExtension>();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.blue),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'Offline models provide better privacy and can work without an internet connection.',
              style: TextStyle(
                color: colors?.textPrimary.withOpacity(0.8),
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarningCard(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorsExtension>();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.orange),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Feature Under Development',
                  style: TextStyle(
                    color: colors?.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Offline Vosk models are currently unavailable due to package compatibility issues. The infrastructure is ready and will be activated when a compatible package becomes available.',
                  style: TextStyle(
                    color: colors?.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
