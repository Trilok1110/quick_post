import 'package:flutter/material.dart';
import '../controllers/theme_controller.dart';
import '../services/remote_config_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final ThemeController _themeController = ThemeController.instance;
  final RemoteConfigService _rc = RemoteConfigService.instance;
  bool _fetching = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Theme', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(value: ThemeMode.system, label: Text('System'), icon: Icon(Icons.brightness_auto)),
              ButtonSegment(value: ThemeMode.light, label: Text('Light'), icon: Icon(Icons.light_mode)),
              ButtonSegment(value: ThemeMode.dark, label: Text('Dark'), icon: Icon(Icons.dark_mode)),
            ],
            selected: {_themeController.mode},
            onSelectionChanged: (set) {
              final mode = set.first;
              _themeController.setMode(mode);
              setState(() {});
            },
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Follow Remote Config defaults'),
                      FilledButton.tonal(
                        onPressed: () async {
                          await _themeController.clearUserPreferenceAndFollowRemote(_rc);
                          if (mounted) setState(() {});
                        },
                        child: const Text('Use Remote'),
                      )
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text('Remote mode: ${_rc.remoteThemeMode.name} | Remote theme ${_rc.useRemoteTheme ? 'ENABLED' : 'DISABLED'}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Remote Config', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      FilledButton.icon(
                        onPressed: _fetching
                            ? null
                            : () async {
                                setState(() => _fetching = true);
                                await _rc.fetchAndActivate();
                                await _themeController.load(rc: _rc);
                                if (mounted) setState(() => _fetching = false);
                              },
                        icon: _fetching
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.sync),
                        label: const Text('Fetch & apply'),
                      ),
                      const SizedBox(width: 12),
                      Text('Seed: ${_rc.seedColor.value.toRadixString(16)}')
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
