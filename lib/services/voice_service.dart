// Automatically picks the correct implementation at compile time:
//   - Web (Chrome/Edge): voice_service_web.dart   → no-op stub
//   - Native (Android/iOS/Windows): voice_service_native.dart → real STT + TTS
export 'voice_service_native.dart' if (dart.library.html) 'voice_service_web.dart';
