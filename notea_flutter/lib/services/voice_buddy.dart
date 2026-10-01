import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Microphone (speech-to-text) + the pet's voice (text-to-speech) for the
/// Feynman "call". If the phone has no speech service, [micAvailable] is
/// false and the screen falls back to typing.
class VoiceBuddy extends ChangeNotifier {
  final SpeechToText _stt = SpeechToText();
  final FlutterTts _tts = FlutterTts();

  bool micAvailable = false;
  bool voiceAvailable = false;
  bool listening = false;
  bool speaking = false;
  bool muted = false;
  String partial = '';
  String? lastError;

  bool _disposed = false;
  bool _delivered = false;
  void Function(String text)? _onFinal;

  Future<void> init() async {
    try {
      micAvailable = await _stt.initialize(
        onError: _onError,
        onStatus: _onStatus,
        options: [SpeechToText.androidNoBluetooth],
      );
    } catch (_) {
      micAvailable = false;
    }
    try {
      await _tts.awaitSpeakCompletion(true);
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(0.48);
      await _tts.setPitch(1.3); // a cute, higher voice for the pet
      _tts.setStartHandler(() => _set(() => speaking = true));
      _tts.setCompletionHandler(() => _set(() => speaking = false));
      _tts.setCancelHandler(() => _set(() => speaking = false));
      _tts.setErrorHandler((_) => _set(() => speaking = false));
      voiceAvailable = true;
    } catch (_) {
      voiceAvailable = false;
    }
    _notify();
  }

  void toggleMute() {
    muted = !muted;
    if (muted) stopSpeaking();
    _notify();
  }

  /// Says [text] out loud (unless muted). Completes when the pet is done talking.
  Future<void> speak(String text) async {
    if (muted || !voiceAvailable) return;
    await stopListening();
    final clean = _forSpeech(text);
    if (clean.isEmpty) return;
    _set(() => speaking = true);
    try {
      await _tts.speak(clean);
    } catch (_) {}
    _set(() => speaking = false);
  }

  Future<void> stopSpeaking() async {
    try {
      await _tts.stop();
    } catch (_) {}
    _set(() => speaking = false);
  }

  /// Starts listening. [onFinal] gets the full sentence once the user stops talking.
  Future<void> listen(void Function(String text) onFinal) async {
    if (!micAvailable) return;
    await stopSpeaking();
    _onFinal = onFinal;
    _delivered = false;
    partial = '';
    lastError = null;
    _set(() => listening = true);
    try {
      await _stt.listen(
        onResult: _onResult,
        listenOptions: SpeechListenOptions(
          partialResults: true,
          cancelOnError: true,
          listenMode: ListenMode.dictation,
          pauseFor: const Duration(seconds: 3),
          listenFor: const Duration(seconds: 60),
        ),
      );
    } catch (_) {
      _set(() => listening = false);
    }
  }

  /// Stops listening; whatever was heard so far is sent as the answer.
  Future<void> stopListening() async {
    if (_stt.isListening) {
      try {
        await _stt.stop();
      } catch (_) {}
    }
    _deliver();
    _set(() => listening = false);
  }

  /// Stops listening and throws away what was heard.
  Future<void> cancelListening() async {
    _delivered = true;
    try {
      await _stt.cancel();
    } catch (_) {}
    partial = '';
    _set(() => listening = false);
  }

  void _onResult(SpeechRecognitionResult r) {
    partial = r.recognizedWords;
    _notify();
    if (r.finalResult) {
      _deliver();
      _set(() => listening = false);
    }
  }

  void _onStatus(String status) {
    if (status == 'done' || status == 'notListening') {
      // Give the final result a moment to arrive, then deliver what we have.
      Future.delayed(const Duration(milliseconds: 600), () {
        _deliver();
        _set(() => listening = false);
      });
    }
  }

  void _onError(SpeechRecognitionError e) {
    // "error_no_match" / "error_speech_timeout" just mean nothing was heard.
    lastError = e.errorMsg.contains('no_match') || e.errorMsg.contains('timeout')
        ? 'I didn\'t hear anything. Tap the mic and try again.'
        : 'Mic problem (${e.errorMsg}). You can type instead.';
    _delivered = true;
    _set(() => listening = false);
  }

  void _deliver() {
    if (_delivered) return;
    final text = partial.trim();
    if (text.isEmpty) return;
    _delivered = true;
    _onFinal?.call(text);
  }

  /// Removes emoji and symbols so the voice doesn't read them out.
  static String _forSpeech(String s) => s
      .replaceAll(RegExp(r'[^\x00-\x7FÀ-ɏ]'), ' ')
      .replaceAll('"', '')
      .replaceAll('_____', 'blank')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  void _set(VoidCallback change) {
    change();
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    try {
      _stt.cancel();
      _tts.stop();
    } catch (_) {}
    super.dispose();
  }
}