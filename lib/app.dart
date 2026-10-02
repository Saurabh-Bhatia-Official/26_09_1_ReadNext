import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'state/settings_provider.dart';
import 'ui/screens/main_shell.dart';
import 'ui/screens/splash_screen.dart';

class ReadNextApp extends ConsumerWidget {
  final bool skipSplash;

  const ReadNextApp({
    super.key,
    this.skipSplash = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    ThemeData selectedTheme;
    switch (settings.themeMode) {
      case AppThemeMode.corporate:
        selectedTheme = AppTheme.corporateTheme;
        break;
      case AppThemeMode.light:
        selectedTheme = AppTheme.lightTheme;
        break;
      case AppThemeMode.sepia:
        selectedTheme = AppTheme.sepiaTheme;
        break;
      case AppThemeMode.dark:
        selectedTheme = AppTheme.darkTheme;
        break;
      case AppThemeMode.system:
        selectedTheme = AppTheme.corporateTheme;
        break;
    }

    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: selectedTheme,
      home: skipSplash ? const MainShell() : const SplashScreen(),
    );
  }
}
