import 'dart:io';

import 'package:fluency/core/services/tts/piper_tts_service.dart';
import 'package:fluency/core/services/tts/system_tts_service.dart';
import 'package:fluency/core/services/tts/tts_service.dart';
import 'package:fluency/core/themes/app_colors_extension.dart';
import 'package:fluency/features/setting/presentation/providers/tts_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:archive/archive_io.dart';
import 'package:provider/provider.dart';

class TtsSettingsPage extends StatefulWidget {
  const TtsSettingsPage({super.key});

  @override
  State<TtsSettingsPage> createState() => _TtsSettingsPageState();
}

class _TtsSettingsPageState extends State<TtsSettingsPage> {
  TtsService? _activeTtsService;
  String _activeEngine = 'System'; // 'System' or 'Piper'
  String? _selectedPiperModel;
  final TextEditingController _testController =
      TextEditingController(text: 'Hello, how are you today?');
  bool _isPlaying = false;
  Map<String, double> _downloadProgress = {};

  final List<PiperModelInfo> _availablePiperModels = [
    // US English Voices
    PiperModelInfo(
        name: 'Arctic (Female, US)',
        code: 'en_US-arctic-medium',
        url:
            'https://huggingface.co/khanhromvn/piper-voice/resolve/main/vits-piper-en_US-arctic-medium.tar.bz2',
        configUrl: '',
        size: '77 MB'),
    PiperModelInfo(
        name: 'Bryce (Male, US)',
        code: 'en_US-bryce-medium',
        url:
            'https://huggingface.co/khanhromvn/piper-voice/resolve/main/vits-piper-en_US-bryce-medium.tar.bz2',
        configUrl: '',
        size: '65 MB'),
    PiperModelInfo(
        name: 'HFC Female (US)',
        code: 'en_US-hfc_female-medium',
        url:
            'https://huggingface.co/khanhromvn/piper-voice/resolve/main/vits-piper-en_US-hfc_female-medium.tar.bz2',
        configUrl: '',
        size: '77 MB'),
    PiperModelInfo(
        name: 'HFC Male (US)',
        code: 'en_US-hfc_male-medium',
        url:
            'https://huggingface.co/khanhromvn/piper-voice/resolve/main/vits-piper-en_US-hfc_male-medium.tar.bz2',
        configUrl: '',
        size: '77 MB'),
    PiperModelInfo(
        name: 'Joe (Male, US)',
        code: 'en_US-joe-medium',
        url:
            'https://huggingface.co/khanhromvn/piper-voice/resolve/main/vits-piper-en_US-joe-medium.tar.bz2',
        configUrl: '',
        size: '77 MB'),
    PiperModelInfo(
        name: 'John (Male, US)',
        code: 'en_US-john-medium',
        url:
            'https://huggingface.co/khanhromvn/piper-voice/resolve/main/vits-piper-en_US-john-medium.tar.bz2',
        configUrl: '',
        size: '77 MB'),
    PiperModelInfo(
        name: 'Kristin (Female, US)',
        code: 'en_US-kristin-medium',
        url:
            'https://huggingface.co/khanhromvn/piper-voice/resolve/main/vits-piper-en_US-kristin-medium.tar.bz2',
        configUrl: '',
        size: '77 MB'),
    PiperModelInfo(
        name: 'Kusal (Male, US)',
        code: 'en_US-kusal-medium',
        url:
            'https://huggingface.co/khanhromvn/piper-voice/resolve/main/vits-piper-en_US-kusal-medium.tar.bz2',
        configUrl: '',
        size: '77 MB'),
    PiperModelInfo(
        name: 'L2 Arctic (Female, US)',
        code: 'en_US-l2arctic-medium',
        url:
            'https://huggingface.co/khanhromvn/piper-voice/resolve/main/vits-piper-en_US-l2arctic-medium.tar.bz2',
        configUrl: '',
        size: '77 MB'),
    PiperModelInfo(
        name: 'Lessac (Female, US)',
        code: 'en_US-lessac-medium',
        url:
            'https://huggingface.co/khanhromvn/piper-voice/resolve/main/vits-piper-en_US-lessac-medium.tar.bz2',
        configUrl: '',
        size: '77 MB'),
    PiperModelInfo(
        name: 'LJSpeech (Female, US)',
        code: 'en_US-ljspeech-medium',
        url:
            'https://huggingface.co/khanhromvn/piper-voice/resolve/main/vits-piper-en_US-ljspeech-medium.tar.bz2',
        configUrl: '',
        size: '77 MB'),
    PiperModelInfo(
        name: 'Norman (Male, US)',
        code: 'en_US-norman-medium',
        url:
            'https://huggingface.co/khanhromvn/piper-voice/resolve/main/vits-piper-en_US-norman-medium.tar.bz2',
        configUrl: '',
        size: '77 MB'),
    PiperModelInfo(
        name: 'Ryan (Male, US)',
        code: 'en_US-ryan-medium',
        url:
            'https://huggingface.co/khanhromvn/piper-voice/resolve/main/vits-piper-en_US-ryan-medium.tar.bz2',
        configUrl: '',
        size: '77 MB'),
    // British English Voices
    PiperModelInfo(
        name: 'Alan (Male, British)',
        code: 'en_GB-alan-medium',
        url:
            'https://huggingface.co/khanhromvn/piper-voice/resolve/main/vits-piper-en_GB-alan-medium.tar.bz2',
        configUrl: '',
        size: '65 MB'),
    PiperModelInfo(
        name: 'Alba (Female, British)',
        code: 'en_GB-alba-medium',
        url:
            'https://huggingface.co/khanhromvn/piper-voice/resolve/main/vits-piper-en_GB-alba-medium.tar.bz2',
        configUrl: '',
        size: '65 MB'),
    PiperModelInfo(
        name: 'Aru (Female, British)',
        code: 'en_GB-aru-medium',
        url:
            'https://huggingface.co/khanhromvn/piper-voice/resolve/main/vits-piper-en_GB-aru-medium.tar.bz2',
        configUrl: '',
        size: '77 MB'),
    PiperModelInfo(
        name: 'Cori (Female, British)',
        code: 'en_GB-cori-medium',
        url:
            'https://huggingface.co/khanhromvn/piper-voice/resolve/main/vits-piper-en_GB-cori-medium.tar.bz2',
        configUrl: '',
        size: '65 MB'),
    PiperModelInfo(
        name: 'Jenny Dioco (Female, British)',
        code: 'en_GB-jenny_dioco-medium',
        url:
            'https://huggingface.co/khanhromvn/piper-voice/resolve/main/vits-piper-en_GB-jenny_dioco-medium.tar.bz2',
        configUrl: '',
        size: '65 MB'),
    PiperModelInfo(
        name: 'Northern Male (British)',
        code: 'en_GB-northern_english_male-medium',
        url:
            'https://huggingface.co/khanhromvn/piper-voice/resolve/main/vits-piper-en_GB-northern_english_male-medium.tar.bz2',
        configUrl: '',
        size: '65 MB'),
    PiperModelInfo(
        name: 'Southern Female (British)',
        code: 'en_GB-southern_english_female-medium',
        url:
            'https://huggingface.co/khanhromvn/piper-voice/resolve/main/vits-piper-en_GB-southern_english_female-medium.tar.bz2',
        configUrl: '',
        size: '77 MB'),
    PiperModelInfo(
        name: 'Southern Male (British)',
        code: 'en_GB-southern_english_male-medium',
        url:
            'https://huggingface.co/khanhromvn/piper-voice/resolve/main/vits-piper-en_GB-southern_english_male-medium.tar.bz2',
        configUrl: '',
        size: '77 MB'),
  ];

  String? _getAvatarPath(String code) {
    final Map<String, String> avatarMap = {
      // US English voices
      'en_US-arctic-medium': 'assets/images/voice_avatars/arctic.png',
      'en_US-bryce-medium': 'assets/images/voice_avatars/bryce.png',
      'en_US-hfc_female-medium': 'assets/images/voice_avatars/hfc_female.png',
      'en_US-hfc_male-medium': 'assets/images/voice_avatars/hfc_male.png',
      'en_US-joe-medium': 'assets/images/voice_avatars/joe.png',
      'en_US-john-medium': 'assets/images/voice_avatars/john.png',
      'en_US-kristin-medium': 'assets/images/voice_avatars/kristin.png',
      'en_US-kusal-medium': 'assets/images/voice_avatars/kusal.png',
      'en_US-l2arctic-medium': 'assets/images/voice_avatars/l2arctic.png',
      'en_US-lessac-medium': 'assets/images/voice_avatars/lessac.png',
      'en_US-ljspeech-medium': 'assets/images/voice_avatars/ljspeech.png',
      'en_US-norman-medium': 'assets/images/voice_avatars/norman.png',
      'en_US-ryan-medium': 'assets/images/voice_avatars/ryan.png',
      // British English voices
      'en_GB-alan-medium': 'assets/images/voice_avatars/alan.png',
      'en_GB-alba-medium': 'assets/images/voice_avatars/alba.png',
      'en_GB-aru-medium': 'assets/images/voice_avatars/aru.png',
      'en_GB-cori-medium': 'assets/images/voice_avatars/cori.png',
    };
    return avatarMap[code];
  }

  @override
  void initState() {
    super.initState();
    _initService();
  }

  Future<void> _initService() async {
    _activeTtsService?.dispose();

    if (_activeEngine == 'System') {
      _activeTtsService = SystemTtsService();
    } else {
      // Piper
      if (_selectedPiperModel == null) {
        // Try to find first available model
        for (var model in _availablePiperModels) {
          if (await _isModelDownloaded(model)) {
            _selectedPiperModel = await _getLocalModelPath(model);
            break;
          }
        }
      }

      final appDir = await getApplicationDocumentsDirectory();
      final espeakPath = path.join(appDir.path, 'espeak-ng-data');

      _activeTtsService = PiperTtsService(
        selectedModelPath: _selectedPiperModel,
        espeakDataPath: Directory(espeakPath).existsSync() ? espeakPath : null,
      );
    }

    await _activeTtsService!.initialize();

    // Listen to state
    _activeTtsService!.stateStream.listen((state) {
      if (!mounted) return;
      setState(() {
        _isPlaying = state == TtsState.playing;
      });
    });

    if (mounted) setState(() {});
  }

  Future<void> _switchEngine(String engine) async {
    if (_activeEngine == engine) return;

    _activeTtsService?.dispose();
    _activeEngine = engine;

    // Auto-select first available model for Piper if none selected
    if (engine == 'Piper' && _selectedPiperModel == null) {
      // Check availability
      for (var model in _availablePiperModels) {
        if (await _isModelDownloaded(model)) {
          _selectedPiperModel = await _getLocalModelPath(model);
          break;
        }
      }
    }

    await _initService();
  }

  Future<bool> _isModelDownloaded(PiperModelInfo model) async {
    final appDir = await getApplicationDocumentsDirectory();
    final extractedFolder = 'vits-piper-${model.code}';
    final modelPath = path.join(
        appDir.path, 'piper_models', extractedFolder, '${model.code}.onnx');

    // DEBUG: print path checking
    debugPrint('Checking model path: $modelPath');
    debugPrint('Exists: ${File(modelPath).existsSync()}');

    return File(modelPath).existsSync();
  }

  Future<String?> _getLocalModelPath(PiperModelInfo model) async {
    final appDir = await getApplicationDocumentsDirectory();
    final extractedFolder = 'vits-piper-${model.code}';
    final modelPath = path.join(
        appDir.path, 'piper_models', extractedFolder, '${model.code}.onnx');

    if (File(modelPath).existsSync()) {
      return modelPath;
    }
    return null;
  }

  Future<void> _downloadModel(PiperModelInfo model) async {
    try {
      setState(() {
        _downloadProgress[model.code] = 0.0;
      });

      final appDir = await getApplicationDocumentsDirectory();
      final downloadDir = Directory(path.join(appDir.path, 'piper_models'));
      if (!downloadDir.existsSync()) {
        await downloadDir.create(recursive: true);
      }

      final fileName = path.basename(model.url);
      final filePath = path.join(downloadDir.path, fileName);

      // Download
      final response = await http.get(Uri.parse(model.url));
      await File(filePath).writeAsBytes(response.bodyBytes);

      setState(() {
        _downloadProgress[model.code] = 0.5;
      });

      // Extract
      final bytes = await File(filePath).readAsBytes();
      final archive =
          TarDecoder().decodeBytes(BZip2Decoder().decodeBytes(bytes));

      for (final file in archive) {
        final filename = file.name;
        if (file.isFile) {
          final data = file.content as List<int>;
          final extractPath = path.join(downloadDir.path, filename);
          await File(extractPath).create(recursive: true);
          await File(extractPath).writeAsBytes(data);
        }
      }

      // Cleanup
      await File(filePath).delete();

      setState(() {
        _downloadProgress.remove(model.code);
      });

      // Auto-select if no model selected
      if (_selectedPiperModel == null && _activeEngine == 'Piper') {
        _selectedPiperModel = await _getLocalModelPath(model);
        await _initService();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${model.name} downloaded successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _downloadProgress.remove(model.code);
      });
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

  Future<void> _deleteModel(PiperModelInfo model) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final extractedFolder = 'vits-piper-${model.code}';
      final baseDir =
          Directory(path.join(appDir.path, 'piper_models', extractedFolder));

      if (baseDir.existsSync()) {
        await baseDir.delete(recursive: true);
      }

      if (_selectedPiperModel != null &&
          _selectedPiperModel!.contains(model.code)) {
        _selectedPiperModel = null;
        if (_activeEngine == 'Piper') _initService();
      }

      setState(() {});
    } catch (e) {
      debugPrint('Delete failed: $e');
    }
  }

  @override
  void dispose() {
    _activeTtsService?.dispose();
    _testController.dispose();
    super.dispose();
  }

  List<PiperModelInfo> get _usVoices =>
      _availablePiperModels.where((m) => m.code.startsWith('en_US')).toList();

  List<PiperModelInfo> get _britishVoices =>
      _availablePiperModels.where((m) => m.code.startsWith('en_GB')).toList();

  List<PiperModelInfo> get _maleVoices => _availablePiperModels.where((m) {
        final name = m.name.toLowerCase();
        final code = m.code.toLowerCase();
        return name.contains('male') ||
            code.contains('bryce') ||
            code.contains('joe') ||
            code.contains('john') ||
            code.contains('kusal') ||
            code.contains('norman') ||
            code.contains('ryan') ||
            code.contains('alan') ||
            code.contains('northern_english_male') ||
            code.contains('southern_english_male') ||
            code.contains('hfc_male');
      }).toList();

  List<PiperModelInfo> get _femaleVoices => _availablePiperModels.where((m) {
        final name = m.name.toLowerCase();
        final code = m.code.toLowerCase();
        return name.contains('female') ||
            code.contains('arctic') ||
            code.contains('kristin') ||
            code.contains('l2arctic') ||
            code.contains('lessac') ||
            code.contains('ljspeech') ||
            code.contains('alba') ||
            code.contains('aru') ||
            code.contains('cori') ||
            code.contains('jenny_dioco') ||
            code.contains('southern_english_female') ||
            code.contains('hfc_female');
      }).toList();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorsExtension>()!;
    final primary = colors.primary;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header
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
                            colors.textPrimary,
                            BlendMode.srcIn,
                          ),
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ),
                    // Centered Title
                    Text(
                      'Voice Settings',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colors.textPrimary,
                          ),
                    ),
                  ],
                ),
              ),
            ),

            // Engine Selector
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colors.cardBackground,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: colors.border.withOpacity(0.5),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildEngineOption(
                        'System',
                        'Device built-in voice',
                        Icons.phone_android,
                        colors,
                        primary,
                      ),
                      Divider(
                        height: 16,
                        color: colors.divider.withOpacity(0.5),
                      ),
                      _buildEngineOption(
                        'Piper',
                        'High quality AI voices',
                        Icons.mic,
                        colors,
                        primary,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Default Voice Selection (only if Piper selected)
            if (_activeEngine == 'Piper') ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 20, 12, 12),
                  child: Text(
                    'Default Voices',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary,
                        ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Column(
                    children: [
                      _buildDefaultVoiceSelector(
                          'Male', _maleVoices, colors, primary),
                      const SizedBox(height: 12),
                      _buildDefaultVoiceSelector(
                          'Female', _femaleVoices, colors, primary),
                    ],
                  ),
                ),
              ),
            ],

            // Voice Sections (only if Piper selected)
            if (_activeEngine == 'Piper') ...[
              // US English Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: Text(
                    'US English',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary,
                        ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final model = _usVoices[index];
                      return _buildVoiceCard(model, colors, primary);
                    },
                    childCount: _usVoices.length,
                  ),
                ),
              ),

              // British English Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 24, 12, 12),
                  child: Text(
                    'British English',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary,
                        ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final model = _britishVoices[index];
                      return _buildVoiceCard(model, colors, primary);
                    },
                    childCount: _britishVoices.length,
                  ),
                ),
              ),

              // Bottom spacing
              const SliverToBoxAdapter(
                child: SizedBox(height: 40),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEngineOption(
    String engine,
    String description,
    IconData icon,
    AppColorsExtension colors,
    Color primary,
  ) {
    final isSelected = _activeEngine == engine;
    return InkWell(
      onTap: () => _switchEngine(engine),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected
                    ? primary.withOpacity(0.1)
                    : colors.textSecondary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: isSelected ? primary : colors.textSecondary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    engine,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isSelected ? primary : colors.textPrimary,
                        ),
                  ),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.textSecondary,
                          fontSize: 12,
                        ),
                  ),
                ],
              ),
            ),
            if (isSelected) Icon(Icons.check_circle, color: primary, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildVoiceCard(
    PiperModelInfo model,
    AppColorsExtension colors,
    Color primary,
  ) {
    return FutureBuilder<bool>(
      future: _isModelDownloaded(model),
      builder: (context, snapshot) {
        final isDownloaded = snapshot.data ?? false;
        final isDownloading = _downloadProgress.containsKey(model.code);
        final isSelected = _selectedPiperModel != null &&
            _selectedPiperModel!.contains(model.code);
        final avatarPath = _getAvatarPath(model.code);

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: colors.cardBackground,
            borderRadius: BorderRadius.circular(12),
            border: isSelected ? Border.all(color: primary, width: 2) : null,
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: primary.withOpacity(0.15),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    )
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    )
                  ],
          ),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            leading: avatarPath != null
                ? Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(color: primary, width: 2)
                          : null,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        avatarPath,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stack) => Icon(
                          isSelected ? Icons.check_circle : Icons.mic_none,
                          color: isSelected ? primary : Colors.grey,
                          size: 24,
                        ),
                      ),
                    ),
                  )
                : Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected
                          ? primary.withOpacity(0.1)
                          : Colors.grey.withOpacity(0.1),
                    ),
                    child: Icon(
                      isSelected ? Icons.check_circle : Icons.mic_none,
                      color: isSelected ? primary : Colors.grey,
                      size: 24,
                    ),
                  ),
            title: Text(
              model.name,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? primary : colors.textPrimary,
              ),
            ),
            subtitle: Text(
              isDownloading
                  ? 'Downloading... ${(_downloadProgress[model.code]! * 100).toStringAsFixed(0)}%'
                  : (isDownloaded
                      ? (isSelected
                          ? 'Selected • ${model.size}'
                          : 'Downloaded • ${model.size}')
                      : '${model.size} • Tap to download'),
              style: TextStyle(
                color: isSelected
                    ? primary.withOpacity(0.8)
                    : colors.textSecondary,
                fontSize: 12,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isDownloading)
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      value: _downloadProgress[model.code],
                      color: primary,
                    ),
                  )
                else if (isDownloaded)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    color: Colors.red.withOpacity(0.8),
                    onPressed: () => _deleteModel(model),
                    tooltip: 'Delete voice',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.download_rounded, size: 20),
                    color: primary,
                    onPressed: () => _downloadModel(model),
                    tooltip: 'Download voice',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
            onTap: () async {
              if (isDownloaded) {
                final modelPath = await _getLocalModelPath(model);
                setState(() {
                  _selectedPiperModel = modelPath;
                });
                await _initService();
                // Auto-speak to preview voice
                _activeTtsService
                    ?.speak('Hello, this is ${model.name.split(' ')[0]}');
              } else {
                _downloadModel(model);
              }
            },
          ),
        );
      },
    );
  }

  Widget _buildDefaultVoiceSelector(
    String gender,
    List<PiperModelInfo> voices,
    AppColorsExtension colors,
    Color primary,
  ) {
    final ttsProvider = context.watch<TtsProvider>();
    final currentDefault = gender == 'Male'
        ? ttsProvider.defaultMaleVoice
        : ttsProvider.defaultFemaleVoice;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Icon(
            gender == 'Male' ? Icons.man : Icons.woman,
            color: colors.textSecondary,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Default $gender Voice',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                FutureBuilder<List<PiperModelInfo>>(
                  future: _getDownloadedVoices(voices),
                  builder: (context, snapshot) {
                    final downloaded = snapshot.data ?? [];
                    if (downloaded.isEmpty) {
                      return Text(
                        'No $gender voices downloaded',
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.textSecondary,
                        ),
                      );
                    }

                    return DropdownButton<String>(
                      value: currentDefault,
                      hint: Text(
                        'Select default $gender voice',
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.textSecondary,
                        ),
                      ),
                      isExpanded: true,
                      underline: const SizedBox(),
                      items: downloaded.map((voice) {
                        return DropdownMenuItem<String>(
                          value: voice.code,
                          child: Text(
                            voice.name,
                            style: TextStyle(
                              fontSize: 12,
                              color: colors.textPrimary,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          if (gender == 'Male') {
                            ttsProvider.setDefaultMaleVoice(value);
                          } else {
                            ttsProvider.setDefaultFemaleVoice(value);
                          }
                        }
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<List<PiperModelInfo>> _getDownloadedVoices(
      List<PiperModelInfo> voices) async {
    final downloaded = <PiperModelInfo>[];
    for (final voice in voices) {
      if (await _isModelDownloaded(voice)) {
        downloaded.add(voice);
      }
    }
    return downloaded;
  }
}

class PiperModelInfo {
  final String name;
  final String code;
  final String url;
  final String configUrl;
  final String size;

  PiperModelInfo({
    required this.name,
    required this.code,
    required this.url,
    required this.configUrl,
    required this.size,
  });
}
