import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'l10n.dart';
import 'providers/cycle_provider.dart';
import 'providers/locale_notifier.dart';
import 'providers/theme_notifier.dart';
import 'screens/splash_screen.dart';
import 'services/storage_service.dart';
import 'utils/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await StorageService.init();
  runApp(const LunaApp());
}

class LunaApp extends StatelessWidget {
  const LunaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CycleProvider()),
        ChangeNotifierProvider(create: (_) => ThemeNotifier()..init()),
        ChangeNotifierProvider(create: (_) => LocaleNotifier()..init()),
      ],
      child: Consumer2<ThemeNotifier, LocaleNotifier>(
        builder: (context, themeNotifier, localeNotifier, _) => MaterialApp(
          title: 'Luna Track',
          debugShowCheckedModeBanner: false,
          themeMode: themeNotifier.themeMode,

          // Localization
          locale: localeNotifier.locale,
          supportedLocales: const [Locale('en'), Locale('vi')],
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],

          theme:     AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,

          home: const SplashScreen(),
        ),
      ),
    );
  }
}
