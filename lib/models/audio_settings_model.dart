class AudioSettingsModel {
  final bool enableTTS;
  final String voice;
  final String style;
  final bool enableHalfwayCue;
  final bool enableCountdownCue;

  const AudioSettingsModel({
    this.enableTTS = true,
    this.voice = 'US Female',
    this.style = 'Calm',
    this.enableHalfwayCue = true,
    this.enableCountdownCue = true,
  });

  AudioSettingsModel copyWith({
    bool? enableTTS,
    String? voice,
    String? style,
    bool? enableHalfwayCue,
    bool? enableCountdownCue,
  }) {
    return AudioSettingsModel(
      enableTTS: enableTTS ?? this.enableTTS,
      voice: voice ?? this.voice,
      style: style ?? this.style,
      enableHalfwayCue: enableHalfwayCue ?? this.enableHalfwayCue,
      enableCountdownCue: enableCountdownCue ?? this.enableCountdownCue,
    );
  }
}
