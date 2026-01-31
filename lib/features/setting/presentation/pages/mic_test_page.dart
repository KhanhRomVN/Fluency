import 'package:fluency/core/services/stt/stt_service.dart';
import 'package:fluency/core/services/stt/system_stt_service.dart';
import 'package:fluency/core/services/stt/vosk_stt_service.dart';
import 'package:fluency/core/themes/app_colors_extension.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart'; // For LocaleName
import 'dart:async'; // For StreamSubscription

class MicTestPage extends StatefulWidget {
  const MicTestPage({super.key});

  @override
  State<MicTestPage> createState() => _MicTestPageState();
}

class _MicTestPageState extends State<MicTestPage> {
  // Use SystemSttService directly for diagnosis as it wraps the platform channel
  SttService _sttService = SystemSttService();

  bool _isInitialized = false;
  bool _isListening = false;
  String _status = 'Not Initialized';
  String _recognizedText = '';
  String? _error;
  List<LocaleName> _availableLocales = [];

  StreamSubscription<String>? _statusSubscription;
  StreamSubscription<String>? _errorSubscription;

  @override
  void initState() {
    super.initState();
    _loadSttService();
  }

  Future<void> _loadSttService() async {
    setState(() {
      _status = 'Loading Settings...';
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final providerType = prefs.getString('stt_provider_type') ?? 'system';
      final modelId = prefs.getString('stt_selected_model');

      print('FluencyLog: Loading STT Service: $providerType');

      if (providerType == 'vosk') {
        _sttService = VoskSttService(selectedModelId: modelId);
      } else {
        _sttService = SystemSttService();
      }

      await _initStt();
    } catch (e) {
      print('FluencyLog: Error loading settings: $e');
      // Fallback to system
      _sttService = SystemSttService();
      await _initStt();
    }
  }

  Future<void> _initStt() async {
    setState(() {
      _status = 'Initializing...';
    });

    try {
      print('FluencyLog: Initializing STT...');
      final available = await _sttService.initialize();
      print('FluencyLog: STT Initialized. Available: $available');

      // Subscribe to streams
      _statusSubscription = _sttService.statusStream.listen((status) {
        if (mounted) {
          setState(() {
            _status = status;
            if (status == 'notListening' ||
                status == 'done' ||
                status == 'doneNoResult') {
              _isListening = false;
            } else if (status == 'listening') {
              _isListening = true;
            }
          });
        }
      });

      _errorSubscription = _sttService.errorStream.listen((errorMsg) {
        if (mounted) {
          setState(() {
            _status = 'Error';
            _error = errorMsg;
            _isListening = false;
          });
        }
      });

      List<LocaleName> locales = [];
      try {
        locales = await _sttService.getLocales();
        print(
            'FluencyLog: Available Locales: ${locales.map((l) => "${l.name}:${l.localeId}").toList()}');
      } catch (e) {
        print('FluencyLog: Failed to get locales: $e');
      }

      if (mounted) {
        setState(() {
          _isInitialized = available;
          _status = available ? 'Ready' : 'Unavailable (Check Permissions)';
          _availableLocales = locales;
        });
      }
    } catch (e) {
      print('FluencyLog: STT Initialization Error: $e');
      if (mounted) {
        setState(() {
          _status = 'Initialization Failed';
          _error = e.toString();
        });
      }
    }
  }

  Future<void> _toggleListening() async {
    if (!_isInitialized) return;

    if (_isListening) {
      print('FluencyLog: Stopping listening...');
      await _sttService.stopListening();
      setState(() {
        _isListening = false;
        _status = 'Stopped';
      });
    } else {
      setState(() {
        _status = 'Listening...';
        _recognizedText = '';
        _error = null;
      });

      try {
        print('FluencyLog: Starting listening...');
        // Try to use system locale if available, else default
        final systemLocaleId = _availableLocales.isNotEmpty
            ? _availableLocales.first.localeId
            : null;
        print(
            'FluencyLog: Using locale: ${systemLocaleId ?? "default (en_US)"}');

        await _sttService.startListening(
          onResult: (text, isFinal) {
            print('FluencyLog: Result: $text (Final: $isFinal)');
            setState(() {
              _recognizedText = text;
              if (isFinal) {
                // Status stream handles stop logic
              }
            });
          },
          onSoundLevel: null,
          localeId: systemLocaleId,
        );
        print('FluencyLog: Listening started successfully command sent.');
        setState(() {
          _isListening = true;
        });
      } catch (e) {
        print('FluencyLog: Error Starting Listening: $e');
        setState(() {
          _isListening = false;
          _status = 'Error Starting';
          _error = e.toString();
        });
      }
    }
  }

  @override
  void dispose() {
    _statusSubscription?.cancel();
    _errorSubscription?.cancel();
    // If we were listening, stop it
    if (_isListening) {
      _sttService.stopListening();
    }
    // Note system STT usually doesn't need explicit dispose of the service instance
    // if it's just wrapping static channel, but good practice if it did.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorsExtension>();
    final primaryColor = colors?.primary ?? Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Microphone Test'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors?.cardBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: colors?.divider.withOpacity(0.1) ??
                      Colors.grey.withOpacity(0.1),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    'Engine: ${_sttService.serviceId}',
                    style: TextStyle(
                      color: colors?.textSecondary,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Status',
                    style: TextStyle(
                      color: colors?.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _status,
                    style: TextStyle(
                      color: _status.contains('Error') ||
                              _status.contains('Unavailable')
                          ? Colors.red
                          : (_isListening ? Colors.green : colors?.textPrimary),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Result Area
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors?.cardBackground.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: colors?.divider.withOpacity(0.1) ??
                        Colors.grey.withOpacity(0.1),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recognized Text:',
                      style: TextStyle(
                        color: colors?.textSecondary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Text(
                          _recognizedText.isEmpty
                              ? (_isListening
                                  ? 'Speak now...'
                                  : 'Tap Mic to start')
                              : _recognizedText,
                          style: TextStyle(
                            color: _recognizedText.isEmpty
                                ? colors?.textSecondary.withOpacity(0.5)
                                : colors?.textPrimary,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            const SizedBox(height: 48),

            // Mic Button with Circular Ripple (Removed, just button now)
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Main Button
                  SizedBox(
                    width: 60,
                    height: 60,
                    child: FloatingActionButton(
                      onPressed: _isInitialized ? _toggleListening : null,
                      backgroundColor: _isListening ? Colors.red : primaryColor,
                      elevation: 0,
                      shape: const CircleBorder(), // Ensure it's round
                      child: Icon(
                        _isListening ? Icons.stop : Icons.mic,
                        size: 28, // Reduced icon size
                        color: Colors.white,
                      ),
                    ),
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
}
