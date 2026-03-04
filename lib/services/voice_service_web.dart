// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:js_util' as js_util;
import 'package:flutter/material.dart';

/// Web implementation of VoiceService using the browser's native Web Speech API.
/// Works in Chrome and Edge. Falls back gracefully if not supported.
class VoiceService extends ChangeNotifier {
  bool _isListening = false;
  String _recognizedText = '';
  dynamic _recognition; // SpeechRecognition JS object
  bool _isVoiceEnabled = false; // off by default until user enables

  bool get isListening => _isListening;
  bool get isVoiceEnabled => _isVoiceEnabled;
  String get recognizedText => _recognizedText;

  void toggleVoice() {
    _isVoiceEnabled = !_isVoiceEnabled;
    if (!_isVoiceEnabled && _isListening) {
      stopListening();
    }
    notifyListeners();
  }

  VoiceService() {
    _initRecognition();
  }

  void _initRecognition() {
    try {
      // Try webkit prefix first (Chrome), then standard
      final ctor = js_util.getProperty(html.window, 'SpeechRecognition') ??
          js_util.getProperty(html.window, 'webkitSpeechRecognition');
      if (ctor == null) {
        print('VoiceService: Web Speech API not available in this browser.');
        return;
      }
      _recognition = js_util.callConstructor(ctor, []);
      js_util.setProperty(_recognition, 'continuous', false);
      js_util.setProperty(_recognition, 'interimResults', true);
      js_util.setProperty(_recognition, 'lang', 'en-US');
    } catch (e) {
      print('VoiceService: Failed to init speech recognition: $e');
    }
  }

  void setLocale(String localeId) {
    if (_recognition == null) return;
    final lang = localeId.startsWith('hi') ? 'hi-IN' : 'en-US';
    js_util.setProperty(_recognition, 'lang', lang);
  }

  Future<void> startListening(Function(String) onResult) async {
    if (_recognition == null) {
      print('VoiceService: Speech recognition not available.');
      return;
    }
    if (_isListening) return;

    _isListening = true;
    _recognizedText = '';
    notifyListeners();

    // onresult — fires as partial and final results come in
    js_util.setProperty(
      _recognition,
      'onresult',
      js_util.allowInterop((event) {
        final results = js_util.getProperty(event, 'results');
        final length = js_util.getProperty(results, 'length') as int;
        String transcript = '';
        bool isFinal = false;

        for (int i = 0; i < length; i++) {
          final result = js_util.callMethod(results, 'item', [i]);
          final alt = js_util.callMethod(result, 'item', [0]);
          transcript += js_util.getProperty(alt, 'transcript') as String;
          if (js_util.getProperty(result, 'isFinal') == true) {
            isFinal = true;
          }
        }

        _recognizedText = transcript;
        notifyListeners();

        if (isFinal) {
          onResult(transcript);
          _isListening = false;
          notifyListeners();
        }
      }),
    );

    // onend — speech recognition session ended
    js_util.setProperty(
      _recognition,
      'onend',
      js_util.allowInterop((_) {
        _isListening = false;
        notifyListeners();
      }),
    );

    // onerror
    js_util.setProperty(
      _recognition,
      'onerror',
      js_util.allowInterop((event) {
        final error = js_util.getProperty(event, 'error');
        print('VoiceService: Speech recognition error: $error');
        _isListening = false;
        notifyListeners();
      }),
    );

    js_util.callMethod(_recognition, 'start', []);
  }

  Future<void> stopListening() async {
    if (_recognition != null && _isListening) {
      js_util.callMethod(_recognition, 'stop', []);
    }
    _isListening = false;
    notifyListeners();
  }

  Future<void> speak(String text) async {
    try {
      final utterance = js_util.callConstructor(
        js_util.getProperty(html.window, 'SpeechSynthesisUtterance'),
        [text],
      );
      js_util.callMethod(
        js_util.getProperty(html.window, 'speechSynthesis'),
        'speak',
        [utterance],
      );
    } catch (e) {
      print('VoiceService: TTS error: $e');
    }
  }

  Future<void> stopSpeaking() async {
    try {
      js_util.callMethod(
        js_util.getProperty(html.window, 'speechSynthesis'),
        'cancel',
        [],
      );
    } catch (_) {}
  }
}
