import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Text-to-Speech service for reading flashcard content aloud.
///
/// Uses on-device TTS (no API cost). Preferences stored in SharedPreferences.
class TtsService {
  static final TtsService _instance = TtsService._();
  static TtsService get instance => _instance;
  TtsService._();

  FlutterTts? _tts;
  bool _isSpeaking = false;
  bool _isEnabled = true;
  bool _isAutoRead = false;

  /// Whether TTS is currently speaking.
  bool get isSpeaking => _isSpeaking;

  /// Whether TTS is enabled (user preference).
  bool get isEnabled => _isEnabled;

  /// Whether to auto-read the answer when revealed.
  bool get isAutoRead => _isAutoRead;

  /// Initialize the TTS engine and load preferences.
  Future<void> init() async {
    _tts = FlutterTts();

    // Configure TTS
    await _tts!.setLanguage('en-US');
    await _tts!.setSpeechRate(0.48);
    await _tts!.setVolume(1.0);
    await _tts!.setPitch(1.0);

    _tts!.setStartHandler(() => _isSpeaking = true);
    _tts!.setCompletionHandler(() => _isSpeaking = false);
    _tts!.setCancelHandler(() => _isSpeaking = false);
    _tts!.setErrorHandler((_) => _isSpeaking = false);

    // Load preferences
    final prefs = await SharedPreferences.getInstance();
    _isEnabled = prefs.getBool('tts_enabled') ?? true;
    _isAutoRead = prefs.getBool('tts_auto_read') ?? false;
  }

  /// Speak the given text. Stops any current speech first.
  Future<void> speak(String text) async {
    if (!_isEnabled || _tts == null || text.trim().isEmpty) return;

    // Strip LaTeX markers for cleaner speech
    final cleaned = _cleanForSpeech(text);
    if (cleaned.isEmpty) return;

    await stop();
    await _tts!.speak(cleaned);
  }

  /// Stop any current speech.
  Future<void> stop() async {
    if (_tts == null) return;
    await _tts!.stop();
    _isSpeaking = false;
  }

  /// Toggle TTS enabled state and persist.
  Future<void> setEnabled(bool enabled) async {
    _isEnabled = enabled;
    if (!enabled) await stop();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tts_enabled', enabled);
  }

  /// Toggle auto-read state and persist.
  Future<void> setAutoRead(bool autoRead) async {
    _isAutoRead = autoRead;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tts_auto_read', autoRead);
  }

  /// Clean text for speech: remove LaTeX, markdown, etc.
  String _cleanForSpeech(String text) {
    var cleaned = text;
    // Remove LaTeX $...$ and \(...\) blocks
    cleaned = cleaned.replaceAll(RegExp(r'\$[^$]+\$'), ' math expression ');
    cleaned = cleaned.replaceAll(RegExp(r'\\\(.*?\\\)'), ' math expression ');
    cleaned = cleaned.replaceAll(RegExp(r'\\\[.*?\\\]'), ' math expression ');
    // Remove markdown bold/italic markers
    cleaned = cleaned.replaceAll(RegExp(r'[*_]{1,3}'), '');
    // Remove extra whitespace
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();
    return cleaned;
  }

  /// Dispose the TTS engine.
  Future<void> dispose() async {
    await stop();
    _tts = null;
  }
}
