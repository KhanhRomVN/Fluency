import 'package:fluency/core/themes/app_colors_extension.dart';
import 'package:fluency/features/collection/domain/entities/term.dart';
import 'package:fluency/features/collection/presentation/widgets/quiz/collection_flashcard.dart';
import 'package:fluency/features/collection/presentation/widgets/quiz/collection_builder.dart';
import 'package:fluency/features/collection/presentation/widgets/quiz/collection_multiple_choice.dart';
import 'package:fluency/features/collection/presentation/widgets/quiz/collection_pronunciation_drill.dart';
import 'package:fluency/features/collection/presentation/widgets/quiz/collection_sentence_builder.dart';
import 'package:fluency/features/quiz/presentation/providers/sound_effect_provider.dart';
import 'package:fluency/features/quiz/presentation/widgets/tutorial_drawer.dart';
import 'package:fluency/features/setting/presentation/providers/tts_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'dart:math' show pi;

class CollectionQuizPage extends StatefulWidget {
  const CollectionQuizPage({
    required this.quizType,
    required this.collectionId,
    required this.terms,
    required this.initialIndex,
    super.key,
  });

  final String quizType;
  final String collectionId;
  final List<Term> terms;
  final int initialIndex;

  @override
  State<CollectionQuizPage> createState() => _CollectionQuizPageState();
}

class _CollectionQuizPageState extends State<CollectionQuizPage>
    with TickerProviderStateMixin {
  late int _currentIndex;
  late AnimationController _tutorialPulseController;
  late Animation<double> _tutorialPulseAnimation;
  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;

    // Initialize tutorial rotation animation (Sweep effect)
    _tutorialPulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();

    _tutorialPulseAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * pi,
    ).animate(CurvedAnimation(
      parent: _tutorialPulseController,
      curve: Curves.linear,
    ));
  }

  @override
  void dispose() {
    _tutorialPulseController.dispose();
    super.dispose();
  }

  String get _quizTitle {
    switch (widget.quizType) {
      case 'flashcard':
        return 'Flashcards';
      case 'builder':
        return 'Word Builder';
      case 'multiple_choice':
        return 'Multiple Choice';
      case 'pronunciation_drill':
        return 'Pronunciation';
      case 'sentence_builder':
        return 'Sentence Builder';
      default:
        return 'Quiz';
    }
  }

  void _showQuizSettingsDrawer(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final appColors = Theme.of(context).extension<AppColorsExtension>()!;

        return Container(
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
                            'Quiz Settings',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: appColors.textPrimary,
                              letterSpacing: -0.5,
                            ),
                          ),
                          Text(
                            'Customize your quiz experience',
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Consumer<TtsProvider>(
                      builder: (context, ttsProvider, child) {
                        final isFemale =
                            ttsProvider.preferredGender == 'female';
                        return _buildQuizSettingOption(
                          context: context,
                          appColors: appColors,
                          icon: Icons.record_voice_over_outlined,
                          title: 'Voice Gender',
                          subtitle: isFemale ? 'Female Voice' : 'Male Voice',
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                          ),
                          trailing: _VoiceToggle(
                            isFemale: isFemale,
                            onChanged: (v) => ttsProvider
                                .setPreferredGender(v ? 'female' : 'male'),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    Consumer<SoundEffectProvider>(
                      builder: (context, soundProvider, child) {
                        return _buildQuizSettingOption(
                          context: context,
                          appColors: appColors,
                          icon: Icons.volume_up_outlined,
                          title: 'Sound Effects',
                          subtitle: soundProvider.isSoundEnabled
                              ? 'Enabled'
                              : 'Disabled',
                          gradient: const LinearGradient(
                            colors: [Color(0xFF10B981), Color(0xFF0EA5E9)],
                          ),
                          trailing: _PremiumToggle(
                            value: soundProvider.isSoundEnabled,
                            onChanged: (v) => soundProvider.setSoundEnabled(v),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuizSettingOption({
    required BuildContext context,
    required AppColorsExtension appColors,
    required IconData icon,
    required String title,
    required String subtitle,
    required Gradient gradient,
    required Widget trailing,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: appColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: appColors.border,
        ),
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
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: appColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: appColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }

  void _showTutorialDrawer(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TutorialDrawer(
        isOpen: true,
        onClose: () => Navigator.pop(context),
        content: '',
        quizType: widget.quizType,
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: appColors.cardBackground,
        border: Border(
          bottom: BorderSide(
            color: appColors.border.withValues(alpha: 0.5),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Back button
          Container(
            decoration: BoxDecoration(
              color: appColors.textPrimary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: InkWell(
              onTap: () => Navigator.pop(context),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: SvgPicture.asset(
                  'assets/icons/chevron_left.svg',
                  width: 20,
                  height: 20,
                  colorFilter: ColorFilter.mode(
                    appColors.textPrimary.withValues(alpha: 0.6),
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
          ),

          // Center: Quiz text + Badge
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _quizTitle,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: appColors.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: appColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${_currentIndex + 1}/${widget.terms.length}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: appColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                ),
              ),
            ],
          ),

          // Right: Icon row
          Row(
            children: [
              // Tutorial icon
              AnimatedBuilder(
                animation: _tutorialPulseAnimation,
                builder: (context, child) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      // The Sweep Highlight
                      CustomPaint(
                        size: const Size(32, 32),
                        painter: _SweepPainter(
                          angle: _tutorialPulseAnimation.value,
                          color: Colors.orange,
                        ),
                      ),
                      // The styled button container
                      Container(
                        decoration: BoxDecoration(
                          color: appColors.textPrimary.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: InkWell(
                          onTap: () => _showTutorialDrawer(context),
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: SvgPicture.string(
                              '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><path d="M9.09 9a3 3 0 0 1 5.83 1c0 2-3 3-3 3"/><path d="M12 17h.01"/></svg>''',
                              width: 16,
                              height: 16,
                              colorFilter: const ColorFilter.mode(
                                Colors.orange,
                                BlendMode.srcIn,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(width: 8),
              // Settings icon
              Container(
                decoration: BoxDecoration(
                  color: appColors.textPrimary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: InkWell(
                  onTap: () => _showQuizSettingsDrawer(context),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: SvgPicture.string(
                      '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12.22 2h-.44a2 2 0 0 0-2 2v.18a2 2 0 0 1-1 1.73l-.43.25a2 2 0 0 1-2 0l-.15-.08a2 2 0 0 0-2.73.73l-.22.38a2 2 0 0 0 .73 2.73l.15.1a2 2 0 0 1 1 1.72v.51a2 2 0 0 1-1 1.74l-.15.09a2 2 0 0 0-.73 2.73l.22.38a2 2 0 0 0 2.73.73l.15-.08a2 2 0 0 1 2 0l.43.25a2 2 0 0 1 1 1.73V20a2 2 0 0 0 2 2h.44a2 2 0 0 0 2-2v-.18a2 2 0 0 1 1-1.73l.43-.25a2 2 0 0 1 2 0l.15.08a2 2 0 0 0 2.73-.73l.22-.39a2 2 0 0 0-.73-2.73l-.15-.08a2 2 0 0 1-1-1.74v-.5a2 2 0 0 1 1-1.74l.15-.09a2 2 0 0 0 .73-2.73l-.22-.38a2 2 0 0 0-2.73-.73l-.15.08a2 2 0 0 1-2 0l-.43-.25a2 2 0 0 1-1-1.73V4a2 2 0 0 0-2-2z"/><circle cx="12" cy="12" r="3"/></svg>''',
                      width: 16,
                      height: 16,
                      colorFilter: ColorFilter.mode(
                        appColors.textPrimary.withValues(alpha: 0.6),
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;

    Widget quizContent;
    switch (widget.quizType) {
      case 'flashcard':
        quizContent = CollectionFlashcard(
          collectionId: widget.collectionId,
          terms: widget.terms,
          initialIndex: widget.initialIndex,
          onPageChanged: (idx) => setState(() => _currentIndex = idx),
        );
        break;
      case 'builder':
        quizContent = CollectionBuilder(
          collectionId: widget.collectionId,
          terms: widget.terms,
          initialIndex: widget.initialIndex,
          onPageChanged: (idx) => setState(() => _currentIndex = idx),
        );
        break;
      case 'multiple_choice':
        quizContent = CollectionMultipleChoice(
          collectionId: widget.collectionId,
          terms: widget.terms,
          initialIndex: widget.initialIndex,
          onPageChanged: (idx) => setState(() => _currentIndex = idx),
        );
        break;
      case 'pronunciation_drill':
        quizContent = CollectionPronunciationDrill(
          collectionId: widget.collectionId,
          terms: widget.terms,
          initialIndex: widget.initialIndex,
          onPageChanged: (idx) => setState(() => _currentIndex = idx),
        );
        break;
      case 'sentence_builder':
        quizContent = CollectionSentenceBuilder(
          collectionId: widget.collectionId,
          terms: widget.terms,
          initialIndex: widget.initialIndex,
          onPageChanged: (idx) => setState(() => _currentIndex = idx),
        );
        break;
      default:
        quizContent = Center(
          child: Text('Unknown quiz type: ${widget.quizType}'),
        );
    }

    return Scaffold(
      backgroundColor: appColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(context),
            Expanded(child: quizContent),
          ],
        ),
      ),
    );
  }
}

class _PremiumToggle extends StatelessWidget {
  const _PremiumToggle({required this.value, required this.onChanged});
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        width: 40,
        height: 22,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          color: value
              ? const Color(0xFF3B82F6).withValues(alpha: 0.25)
              : const Color(0xFF3B82F6).withValues(alpha: 0.15),
          border: Border.all(
            color: value
                ? const Color(0xFF3B82F6).withValues(alpha: 0.5)
                : const Color(0xFF2563EB).withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 300),
          curve: const Cubic(0.34, 1.56, 0.64, 1),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: value ? const Color(0xFF3B82F6) : const Color(0xFFD1D5DB),
              boxShadow: [
                if (value)
                  BoxShadow(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.6),
                    blurRadius: 8,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _VoiceToggle extends StatelessWidget {
  const _VoiceToggle({required this.isFemale, required this.onChanged});
  final bool isFemale;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!isFemale),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        width: 64,
        height: 32,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: isFemale
              ? const Color(0xFFEC4899).withValues(alpha: 0.15)
              : const Color(0xFF3B82F6).withValues(alpha: 0.15),
          border: Border.all(
            color: isFemale
                ? const Color(0xFFEC4899).withValues(alpha: 0.4)
                : const Color(0xFF3B82F6).withValues(alpha: 0.4),
            width: 1.5,
          ),
        ),
        child: Stack(
          children: [
            AnimatedAlign(
              duration: const Duration(milliseconds: 300),
              curve: const Cubic(0.34, 1.56, 0.64, 1),
              alignment:
                  isFemale ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: isFemale
                      ? const Color(0xFFEC4899)
                      : const Color(0xFF3B82F6),
                  boxShadow: [
                    BoxShadow(
                      color: (isFemale
                              ? const Color(0xFFEC4899)
                              : const Color(0xFF3B82F6))
                          .withValues(alpha: 0.4),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Icon(
                  isFemale ? Icons.female_rounded : Icons.male_rounded,
                  color: Colors.white,
                  size: 14,
                ),
              ),
            ),
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: Opacity(
                      opacity: isFemale ? 0.3 : 0,
                      child: const Icon(Icons.male_rounded,
                          size: 14, color: Color(0xFF3B82F6)),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Opacity(
                      opacity: isFemale ? 0 : 0.3,
                      child: const Icon(Icons.female_rounded,
                          size: 14, color: Color(0xFFEC4899)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SweepPainter extends CustomPainter {
  _SweepPainter({required this.angle, required this.color});
  final double angle;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final paint = Paint()
      ..shader = SweepGradient(
        colors: [
          color.withValues(alpha: 0.0),
          color.withValues(alpha: 0.8),
          color.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.5, 1.0],
        transform: GradientRotation(angle),
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(10)),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _SweepPainter oldDelegate) =>
      oldDelegate.angle != angle;
}
