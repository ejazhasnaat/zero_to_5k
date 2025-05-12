import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/audio_settings_service.dart';

class AudioSettingsScreen extends StatelessWidget {
  const AudioSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final audioService = Provider.of<AudioSettingsService>(context);
    final settings = audioService.settings;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Audio Settings'),
      ),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Enable Voice Cues (TTS)'),
            value: settings.enableTTS,
            onChanged: (value) {
              audioService.update(enableTTS: value);
            },
          ),
          ListTile(
            title: const Text('Select Voice'),
            subtitle: Text(settings.voice),
            onTap: () => _showVoicePicker(context, settings.voice, (selected) {
              audioService.update(voice: selected);
            }),
          ),
          ListTile(
            title: const Text('Motivational Style'),
            subtitle: Text(settings.style),
            onTap: () => _showStylePicker(context, settings.style, (selected) {
              audioService.update(style: selected);
            }),
          ),
        ],
      ),
    );
  }

  void _showVoicePicker(BuildContext context, String current, Function(String) onSelected) {
    final options = ['US Female', 'US Male', 'UK Female', 'UK Male'];

    showModalBottomSheet(
      context: context,
      builder: (_) => ListView(
        children: options.map((voice) {
          return RadioListTile<String>(
            title: Text(voice),
            value: voice,
            groupValue: current,
            onChanged: (value) {
              if (value != null) {
                Navigator.pop(context);
                onSelected(value);
              }
            },
          );
        }).toList(),
      ),
    );
  }

  void _showStylePicker(BuildContext context, String current, Function(String) onSelected) {
    final options = ['Calm', 'Energetic', 'Friendly', 'Strict'];

    showModalBottomSheet(
      context: context,
      builder: (_) => ListView(
        children: options.map((style) {
          return RadioListTile<String>(
            title: Text(style),
            value: style,
            groupValue: current,
            onChanged: (value) {
              if (value != null) {
                Navigator.pop(context);
                onSelected(value);
              }
            },
          );
        }).toList(),
      ),
    );
  }
}

