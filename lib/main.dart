import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/app_theme.dart';
import 'models/zone_config.dart';
import 'providers/settings_provider.dart';
import 'providers/stats_provider.dart';
import 'services/ble/ble_constants.dart';
import 'services/ble/ble_sensor_manager.dart';
import 'services/settings_service.dart';
import 'widgets/dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settingsService = SettingsService();
  final initialConfig = await settingsService.load();
  final initialTheme = await settingsService.loadAppTheme();
  final initialSimulate = await settingsService.loadSimulateSensors();

  runApp(CycleApp(
    settingsService: settingsService,
    initialConfig: initialConfig,
    initialTheme: initialTheme,
    initialSimulate: initialSimulate,
  ));
}

class CycleApp extends StatelessWidget {
  const CycleApp({
    super.key,
    required this.settingsService,
    required this.initialConfig,
    this.initialTheme = AppTheme.dark,
    this.initialSimulate = false,
  });

  final SettingsService settingsService;
  final ZoneConfig initialConfig;
  final AppTheme initialTheme;
  final bool initialSimulate;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => SettingsProvider(settingsService)
            ..updateConfig(initialConfig)
            ..setAppTheme(initialTheme)
            ..setSimulateSensors(initialSimulate),
        ),
        ChangeNotifierProvider(
          create: (_) {
            final manager = BleSensorManager(settingsService);
            // Reconnect to any sensors remembered from a previous session.
            for (final role in SensorRole.values) {
              manager.reconnectRemembered(role);
            }
            return manager;
          },
          lazy: false,
        ),
        ChangeNotifierProxyProvider<SettingsProvider, StatsProvider>(
          create: (ctx) => StatsProvider(
            ctx.read<SettingsProvider>().config,
            ble: ctx.read<BleSensorManager>(),
          ),
          update: (_, settings, stats) => stats!
            ..updateSettings(settings.config)
            ..setSimulate(settings.simulateSensors),
        ),
      ],
      child: Consumer<SettingsProvider>(
        builder: (_, settings, __) => MaterialApp(
          title: 'PaceStrip',
          debugShowCheckedModeBanner: false,
          themeMode:
              settings.appTheme.isDark ? ThemeMode.dark : ThemeMode.light,
          theme: buildLightTheme(),
          darkTheme:
              buildDarkTheme(oled: settings.appTheme == AppTheme.black),
          home: const Scaffold(
            body: SafeArea(child: Dashboard()),
          ),
        ),
      ),
    );
  }
}
