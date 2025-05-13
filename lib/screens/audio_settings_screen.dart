import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/audio_settings_service.dart';

class AudioSettingsScreen extends StatelessWidget {
  final List<String> voiceOptions = [
    'US Female',
    'US Male',
    'UK Female',
    'UK Male',
    'IN Female',
    'IN Male',
  ];

  final List<String> styleOptions = [
    'Calm',
    'Energetic',
    'Neutral',
  ];

  @override
  Widget build(BuildContext context) {
    final audioService = Provider.of<AudioSettingsService>(context);
    final settings = audioService.settings;

    return Scaffold(
      appBar: AppBar(title: Text("Audio Settings")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            SwitchListTile(
              title: Text("Enable TTS"),
              value: settings.enableTTS,
              onChanged: (value) {
                audioService.update(enableTTS: value);
              },
            ),
            ListTile(
              title: Text("Voice"),
              trailing: DropdownButton<String>(
                value: settings.voice,
                onChanged: (value) {
                  if (value != null) {
                    audioService.update(voice: value);
                  }
                },
                items: voiceOptions.map((voice) {
                  return DropdownMenuItem(
                    value: voice,
                    child: Text(voice),
                  );
                }).toList(),
              ),
            ),
            ListTile(
              title: Text("Motivational Style"),
              trailing: DropdownButton<String>(
                value: settings.style,
                onChanged: (value) {
                  if (value != null) {
                    audioService.update(style: value);
                  }
                },
                items: styleOptions.map((style) {
                  return DropdownMenuItem(
                    value: style,
                    child: Text(style),
                  );
                }).toList(),
              ),
            ),
            SwitchListTile(
              title: Text("Halfway Cue"),
              value: settings.enableHalfwayCue,
              onChanged: (value) {
                audioService.update(enableHalfwayCue: value);
              },
            ),
            SwitchListTile(
              title: Text("Countdown Cue"),
              value: settings.enableCountdownCue,
              onChanged: (value) {
                audioService.update(enableCountdownCue: value);
              },
            ),
          ],
        ),
      ),
    );
  }
}

