class AudioSettingsModel {
  final bool enableTTS;
  final String voice;
  final String style;

  const AudioSettingsModel({
    this.enableTTS = true,
    this.voice = 'US Female',
    this.style = 'Calm',
  });

  AudioSettingsModel copyWith({
    bool? enableTTS,
    String? voice,
    String? style,
  }) {
    return AudioSettingsModel(
      enableTTS: enableTTS ?? this.enableTTS,
      voice: voice ?? this.voice,
      style: style ?? this.style,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AudioSettingsModel &&
          runtimeType == other.runtimeType &&
          enableTTS == other.enableTTS &&
          voice == other.voice &&
          style == other.style;

  @override
  int get hashCode => enableTTS.hashCode ^ voice.hashCode ^ style.hashCode;
}
