import 'package:audio_session/audio_session.dart';

/// Optimizes routing for speech + low-level bed; allows mix with other audio a bit more safely.
Future<void> configureRadioAudioSession() async {
  final session = await AudioSession.instance;
  await session.configure(
    AudioSessionConfiguration.speech().copyWith(
      avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.mixWithOthers,
      androidAudioAttributes: const AndroidAudioAttributes(
        contentType: AndroidAudioContentType.music,
        flags: AndroidAudioFlags.none,
        usage: AndroidAudioUsage.media,
      ),
      androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
      androidWillPauseWhenDucked: false,
    ),
  );
  await session.setActive(true);
}
