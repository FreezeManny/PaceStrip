import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/zone_config.dart';
import 'providers/settings_provider.dart';
import 'providers/stats_provider.dart';
import 'services/settings_service.dart';
import 'widgets/dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settingsService = SettingsService();
  final initialConfig = await settingsService.load();
  final initialThemeMode = await settingsService.loadThemeMode();

  runApp(CycleApp(
    settingsService: settingsService,
    initialConfig: initialConfig,
    initialThemeMode: initialThemeMode,
  ));
}

class CycleApp extends StatelessWidget {
  const CycleApp({
    super.key,
    required this.settingsService,
    required this.initialConfig,
    this.initialThemeMode = ThemeMode.dark,
  });

  final SettingsService settingsService;
  final ZoneConfig initialConfig;
  final ThemeMode initialThemeMode;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => SettingsProvider(settingsService)
            ..updateConfig(initialConfig)
            ..setThemeMode(initialThemeMode),
        ),
        ChangeNotifierProxyProvider<SettingsProvider, StatsProvider>(
          create: (ctx) =>
              StatsProvider(ctx.read<SettingsProvider>().config),
          update: (_, settings, stats) =>
              stats!..updateSettings(settings.config),
        ),
      ],
      child: Consumer<SettingsProvider>(
        builder: (_, settings, __) => MaterialApp(
          title: 'PaceStrip',
          debugShowCheckedModeBanner: false,
          themeMode: settings.themeMode,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF4FC3F7),
            ),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF4FC3F7),
              brightness: Brightness.dark,
            ),
            scaffoldBackgroundColor: const Color(0xFF0A0A0A),
            useMaterial3: true,
          ),
          home: const Scaffold(
            body: SafeArea(child: Dashboard()),
          ),
        ),
      ),
    );
  }
}
