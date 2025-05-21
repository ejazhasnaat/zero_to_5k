class AudioSettingsModel {
  final bool enableTTS;
  final String voice;
  final String style;

  // Cue toggles
  final bool enableStartCue;
  final bool enablePauseCue;
  final bool enableResumeCue;
  final bool enableIntervalChangeCue;
  final bool enableHalfwayCue;
  final bool enableCountdownCue;

  // Volume control (0.0 - 1.0)
  final double cueVolume;

  const AudioSettingsModel({
    this.enableTTS = true,
    this.voice = 'US Female',
    this.style = 'Energetic',
    this.enableStartCue = true,
    this.enablePauseCue = true,
    this.enableResumeCue = true,
    this.enableIntervalChangeCue = true,
    this.enableHalfwayCue = true,
    this.enableCountdownCue = true,
    this.cueVolume = 1.0,
  });

  AudioSettingsModel copyWith({
    bool? enableTTS,
    String? voice,
    String? style,
    bool? enableStartCue,
    bool? enablePauseCue,
    bool? enableResumeCue,
    bool? enableIntervalChangeCue,
    bool? enableHalfwayCue,
    bool? enableCountdownCue,
    double? cueVolume,
  }) {
    return AudioSettingsModel(
      enableTTS: enableTTS ?? this.enableTTS,
      voice: voice ?? this.voice,
      style: style ?? this.style,
      enableStartCue: enableStartCue ?? this.enableStartCue,
      enablePauseCue: enablePauseCue ?? this.enablePauseCue,
      enableResumeCue: enableResumeCue ?? this.enableResumeCue,
      enableIntervalChangeCue: enableIntervalChangeCue ?? this.enableIntervalChangeCue,
      enableHalfwayCue: enableHalfwayCue ?? this.enableHalfwayCue,
      enableCountdownCue: enableCountdownCue ?? this.enableCountdownCue,
      cueVolume: cueVolume ?? this.cueVolume,
    );
  }

  factory AudioSettingsModel.fromJson(Map<String, dynamic> json) {
    return AudioSettingsModel(
      enableTTS: json['enableTTS'] ?? true,
      voice: json['voice'] ?? 'US Female',
      style: json['style'] ?? 'Energetic',
      enableStartCue: json['enableStartCue'] ?? true,
      enablePauseCue: json['enablePauseCue'] ?? true,
      enableResumeCue: json['enableResumeCue'] ?? true,
      enableIntervalChangeCue: json['enableIntervalChangeCue'] ?? true,
      enableHalfwayCue: json['enableHalfwayCue'] ?? true,
      enableCountdownCue: json['enableCountdownCue'] ?? true,
      cueVolume: (json['cueVolume'] ?? 1.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enableTTS': enableTTS,
      'voice': voice,
      'style': style,
      'enableStartCue': enableStartCue,
      'enablePauseCue': enablePauseCue,
      'enableResumeCue': enableResumeCue,
      'enableIntervalChangeCue': enableIntervalChangeCue,
      'enableHalfwayCue': enableHalfwayCue,
      'enableCountdownCue': enableCountdownCue,
      'cueVolume': cueVolume,
    };
  }
}
