import 'package:fluency/core/themes/app_colors_extension.dart';
import 'package:fluency/features/setting/domain/entities/stt_provider_type.dart';
import 'package:fluency/features/setting/domain/entities/vosk_model.dart';
import 'package:fluency/features/setting/data/services/vosk_model_manager.dart';
import 'package:fluency/features/setting/presentation/providers/stt_setting_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
      backgroundColor: colors?.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Custom Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Back Button
                    Positioned(
                      left: 4,
                      child: IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: SvgPicture.asset(
                          'assets/icons/chevron_left.svg',
                          width: 24,
                          height: 24,
                          colorFilter: ColorFilter.mode(
                            colors?.textPrimary ?? Colors.black,
                            BlendMode.srcIn,
                          ),
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ),
                    // Centered Title
                    Text(
                      'Voice Recognition',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colors?.textPrimary,
                          ),
                    ),
                  ],
                ),
              ),
            ),

            // Provider Type Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: Text(
                  'Recognition Engine',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colors?.textPrimary,
                      ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final type = SttProviderType.values[index];
                    return _buildProviderTypeTile(context, type, sttProvider);
                  },
                  childCount: SttProviderType.values.length,
                ),
              ),
            ),

            // Offline Models Section (only if Vosk selected)
            if (sttProvider.currentProviderType == SttProviderType.vosk) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 24, 12, 12),
                  child: Text(
                    'Offline Models',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colors?.textPrimary,
                        ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final model = VoskModel.availableModels[index];
                      final isDownloaded = _modelDownloaded[model.id] ?? false;
                      final progress = _downloadProgress[model.id];

                      return _buildModelTile(
                        context,
                        model,
                        isDownloaded: isDownloaded,
                        progress: progress,
                        onDownload: () => _downloadModel(model),
                        onDelete: () => _deleteModel(model),
                        onCancel: () => _cancelDownload(model),
                      );
                    },
                    childCount: VoskModel.availableModels.length,
                  ),
                ),
              ),
            ],

            // Bottom spacing
            const SliverToBoxAdapter(
              child: SizedBox(height: 40),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProviderTypeTile(
    BuildContext context,
    SttProviderType type,
    SttSettingProvider provider,
  ) {
    final colors = Theme.of(context).extension<AppColorsExtension>();
    final primaryColor = colors?.primary ?? Theme.of(context).primaryColor;
    final isSelected = provider.currentProviderType == type;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isSelected
            ? primaryColor.withOpacity(0.05)
            : colors?.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected
              ? primaryColor
              : colors?.divider.withOpacity(0.1) ?? Colors.transparent,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
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
        color: colors?.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: isDownloaded && isSelected
            ? Border.all(color: primaryColor, width: 2)
            : null,
        boxShadow: isDownloaded && isSelected
            ? [
                BoxShadow(
                  color: primaryColor.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                )
              ]
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                )
              ],
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
}
