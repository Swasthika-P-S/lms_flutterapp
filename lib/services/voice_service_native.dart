import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';

class VoiceService extends ChangeNotifier {
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();

  bool _isListening = false;
  String _recognizedText = '';
  String _currentLocaleId = 'en_US';
  bool _isVoiceEnabled = false; // off by default until user enables

  bool get isListening => _isListening;
  String get recognizedText => _recognizedText;
  bool get isVoiceEnabled => _isVoiceEnabled;

  void toggleVoice() {
    _isVoiceEnabled = !_isVoiceEnabled;
    if (!_isVoiceEnabled && _isListening) {
      stopListening();
    }
    notifyListeners();
  }

  VoiceService() {
    _initSpeech();
    _initTts();
  }

  Future<void> _initSpeech() async {
    await _speechToText.initialize(
      onError: (error) => print('Speech to text error: $error'),
      onStatus: (status) {
        print('Speech to text status: $status');
        if (status == 'done' || status == 'notListening') {
          _isListening = false;
          notifyListeners();
        }
      },
    );
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage('en-US');
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
  }

  void setLocale(String localeId) {
    _currentLocaleId = localeId;
    if (localeId.startsWith('hi')) {
      _flutterTts.setLanguage('hi-IN');
    } else {
      _flutterTts.setLanguage('en-US');
    }
  }

  Future<void> startListening(Function(String) onResult) async {
    if (!_speechToText.isAvailable) {
      bool available = await _speechToText.initialize();
      if (!available) {
        print('Speech recognition is not available');
        return;
      }
    }

    _isListening = true;
    _recognizedText = '';
    notifyListeners();

    await _speechToText.listen(
      onResult: (result) {
        _recognizedText = result.recognizedWords;
        notifyListeners();
        if (result.finalResult) {
          onResult(result.recognizedWords);
          _isListening = false;
          notifyListeners();
        }
      },
      localeId: _currentLocaleId,
      cancelOnError: true,
      partialResults: true,
    );
  }

  Future<void> stopListening() async {
    await _speechToText.stop();
    _isListening = false;
    notifyListeners();
  }

  Future<void> speak(String text) async {
    await _flutterTts.speak(text);
  }

  Future<void> stopSpeaking() async {
    await _flutterTts.stop();
  }
}
