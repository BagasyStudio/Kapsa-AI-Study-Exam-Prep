import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Lightweight sound effect service for Kapsa.
///
/// Plays short audio cues on key user interactions to provide
/// satisfying haptic-like feedback. All sounds are local assets.
///
/// Usage:
/// ```dart
/// SoundService.playMessageSent();
/// ```
class SoundService {
  SoundService._();

  static final _player = AudioPlayer();
  static bool _enabled = true;
  static const _prefsKey = 'sounds_enabled';

  /// Initialize from saved preferences. Call once at app startup.
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _enabled = prefs.getBool(_prefsKey) ?? true;

    // Configure player for short sound effects
    await _player.setReleaseMode(ReleaseMode.stop);
  }

  /// Whether sound effects are currently enabled.
  static bool get isEnabled => _enabled;

  /// Toggle sound effects on/off and persist the preference.
  static Future<void> setEnabled(bool value) async {
    _enabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, value);
  }

  // ── Sound triggers ──────────────────────────────────────────

  /// User sends a message in chat.
  static Future<void> playMessageSent() => _play('message_sent.mp3');

  /// AI assistant finishes responding.
  static Future<void> playMessageReceived() => _play('message_received.mp3');

  /// Material processing completes (OCR, PDF, paste).
  static Future<void> playProcessingComplete() =>
      _play('processing_complete.mp3');

  /// Capture sheet opens.
  static Future<void> playCaptureStart() => _play('capture_start.mp3');

  /// Flashcard is flipped to reveal answer.
  static Future<void> playFlashcardFlip() => _play('flashcard_flip.mp3');

  /// Correct answer (swipe right / mastered).
  static Future<void> playCorrectAnswer() => _play('correct_answer.mp3');

  /// Wrong answer (swipe left / learning).
  static Future<void> playWrongAnswer() => _play('wrong_answer.mp3');

  /// Streak milestone reached (3, 7, 14, 30, 60, 100, 365 days).
  static Future<void> playStreakMilestone() => _play('streak_milestone.mp3');

  /// Tab switch in bottom navigation.
  static Future<void> playTabSwitch() => _play('tab_switch.mp3');

  // ── Internal ────────────────────────────────────────────────

  static Future<void> _play(String file) async {
    if (!_enabled) return;
    try {
      await _player.stop(); // Stop any currently playing sound
      await _player.play(AssetSource('sounds/$file'));
    } catch (_) {
      // Silently fail — sound effects are non-critical
    }
  }
}
